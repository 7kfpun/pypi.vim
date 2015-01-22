" pypi - Get the latest version of the package in Vim
" Maintainer: kf <7kfpun@gmail.com>

scriptencoding utf-8


function! s:Strip(input_string)
    return substitute(a:input_string, '^\s*\(.\{-}\)\s*$', '\1', '')
endfunction


function! pypi#Pypi(package_name)

    let request_uri = 'https://pypi.python.org/simple/'.a:package_name
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
                let latest_version = split(reverse(sort(versions))[0], '\.tar\.gz')[0]
                return latest_version
            catch
                return 'Package could not be found.'
            endtry
        else
            return 'Package could not be found.'
        endif

    catch
        echoerr 'Something wrong with the internet.'
    endtry

endfunction


function! s:AddComment(line_number, text)
    let replace_text = s:Strip(getline(a:line_number).'  # '.a:text)
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
            let line = ' '.line

            if line =~ '=='
                let package_name = split(line, '==')[0]
            else
                let package_name = line
            endif

            if line =~ '#'
                let package_name = split(line, '#')[0]
            else
                let package_name = line
            endif

            let package_name = s:Strip(package_name)
            if strlen(package_name)
                let latest_version = pypi#Pypi(package_name)
                if strlen(latest_version) > 0
                    echo latest_version
                    let version_number = split(latest_version, '-')[0]

                    if g:enable_add_latest_version
                        call s:AddComment(line_number, latest_version)
                    endif
                endif
            endif
        catch
        endtry

        let line_number = line_number + 1
    endfor

endfunction
