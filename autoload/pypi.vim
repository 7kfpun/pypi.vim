" pypi - Get the latest version of the package in Vim
" Maintainer: kf <7kfpun@gmail.com>

scriptencoding utf-8


function! s:Strip(input_string)
    return substitute(a:input_string, '^\s*\(.\{-}\)\s*$', '\1', '')
endfunction


function! s:CleanLine(line)
    return s:Strip(substitute(a:line, "[#=].*", "", ""))
endfunction


function! pypi#Pypi(package_name)

    let package_name = s:CleanLine(a:package_name)
    if !strlen(package_name)
        return
    endif

    let request_uri = 'https://pypi.python.org/simple/'.package_name
    try
        let response = webapi#http#get(request_uri)
        if response.status == 200
            let dom = webapi#xml#parse(response.content)

            let versions = []

            for a_element in dom.findAll('a')
                if has_key(a_element, 'child') && a_element['child'][0] =~ "\.tar\.gz"
                    call add(versions, a_element['child'][0])
                endif
            endfor

            try
                let latest_version = substitute(reverse(sort(versions))[0], "\.tar.*", "", "")
                return latest_version
            catch
                echomsg 'Package could not be found.'
            endtry
        else
            echomsg 'Package could not be found.'
        endif

    catch
        echoerr 'Something wrong with the internet.'
    endtry

endfunction


function! s:AddComment(line_number, text)
    let replace_text = getline(a:line_number).'  # '.a:text
    call setline(a:line_number, replace_text)
endfunction


function! pypi#PypiReviewSearch(force)

    let filename = expand('%:t')

    if a:force || filename =~ 'requirement' || len(readfile(expand('%:p'))) < g:try_first_n_lines
        let search_packages = readfile(expand('%:p'))
    else
        echomsg 'Only first '.g:try_first_n_lines.' lines would be searched. Use PypiReviewForce to check all lines.'
        let search_packages = readfile(expand('%:p'))[:g:try_first_n_lines]
    endif

    let line_number = 1
    for line in search_packages
        try
            let package_name = s:CleanLine(line)
            let latest_version = pypi#Pypi(package_name)
            if latest_version != '0'
                echo latest_version
                let latest_version = substitute(latest_version, "-", "==", "")

                if g:enable_add_latest_version
                    call s:AddComment(line_number, latest_version)
                endif
            endif
        catch
        endtry

        let line_number = line_number + 1
    endfor

endfunction
