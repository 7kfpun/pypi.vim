" pypi - Get the latest version of the package in Vim
" Maintainer: kf <7kfpun@gmail.com>

scriptencoding utf-8


silent! call webapi#json#decode('{}')
if !exists('*webapi#json#decode')
    echohl ErrorMsg | echomsg "checkip.vim requires webapi (https://github.com/mattn/webapi-vim)" | echohl None
    finish
endif


function! s:Strip(input_string)
    return substitute(a:input_string, '^\s*\(.\{-}\)\s*$', '\1', '')
endfunction


function! Pypi(package)

    let request_uri = 'https://pypi.python.org/simple/'.s:Strip(a:package)
    try
        let dom = webapi#xml#parseURL(request_uri)

        let versions = []

        for a_element in dom.findAll('a')
            if has_key(a_element, 'child')
                if a_element['child'][0] =~ "\.tar\.gz"
                    call add(versions, a_element['child'][0])
                endif
            endif
        endfor

        try
            let latest_version = split(reverse(sort(versions))[0], '\.tar\.gz')[0]
            return latest_version
        catch
            echomsg 'Package could not be found.'
        endtry

    catch
        echoerr 'Something wrong with the internet.'
    endtry

endfunction

command! -nargs=1 Pypi echo Pypi(<f-args>)


function! s:PypiReviewSearch(force)

    let filename = expand('%:t')

    if a:force || filename =~ 'requirement'
        let search_packages = readfile(expand('%:p'))
    else
        echomsg 'Only first 20 lines would be searched.'
        let search_packages = readfile(expand('%:p'))[:20]
    endif


    for line in search_packages
        if line !~ '#'
            if strlen(line)
                if line =~ '=='
                    let package_name = split(line, '==')[0]
                else
                    let package_name = line
                endif
                echo Pypi(package_name)
            endif
        endif
    endfor

endfunction


command! PypiReview call s:PypiReviewSearch(0)
command! PypiReviewForce call s:PypiReviewSearch(1)
