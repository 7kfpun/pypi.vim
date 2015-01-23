" pypi - Get the latest version of the package in Vim
" Maintainer: kf <7kfpun@gmail.com>

scriptencoding utf-8


function! s:Strip(input_string)
    return substitute(a:input_string, '^\s*\(.\{-}\)\s*$', '\1', '')
endfunction


function! s:CleanLine(line)
    return s:Strip(substitute(a:line, "[#=><].*", "", ""))
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
                    call add(versions, substitute(a_element['child'][0], "\.tar.*", "", ""))
                endif
            endfor

            try
                let latest_version = reverse(sort(versions))[0]
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


function! s:ReplaceLatestVersion(line_number, text)
    if g:pypi_replace_with_comment
    let old_line = getline(a:line_number)
        if old_line =~ a:text
            echomsg 'It is already the latest version.'
            return
        endif
        let replace_text = a:text.'  # updated from: '.old_line
    else
        let replace_text = a:text
    endif
    call setline(a:line_number, replace_text)
endfunction


function! s:CheckLine(line, position)
    if a:position == ''
        let a:position = '.'
    endif

    let latest_version = pypi#Pypi(a:line)
    if latest_version != '0'
        if g:pypi_print_results
            echo latest_version
        endif

        if g:pypi_replace_latest_version
            let latest_version = substitute(latest_version, "-", "==", "")
            call s:ReplaceLatestVersion(a:position, latest_version)
        endif
    endif
endfunction


function! pypi#PypiReviewSearch(force)

    let filename = expand('%:t')

    if a:force || filename =~ 'requirement' || len(readfile(expand('%:p'))) < g:pypi_attempt_lines
        let search_packages = readfile(expand('%:p'))
    else
        echomsg 'Only first '.g:pypi_attempt_lines.' lines would be searched. Use PypiReviewForce to check all lines.'
        let search_packages = readfile(expand('%:p'))[:g:pypi_attempt_lines]
    endif

    let line_position = 1
    for line in search_packages
        call s:CheckLine(line, line_position)
        let line_position = line_position + 1
    endfor

endfunction


function! pypi#PypiReviewLines()
    call s:CheckLine(getline('.'), '.')
endfunction
