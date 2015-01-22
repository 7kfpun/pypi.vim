" pypi - Get the latest version of the package in Vim
" Maintainer: kf <7kfpun@gmail.com>

scriptencoding utf-8


function! s:Strip(input_string)
    return substitute(a:input_string, '^\s*\(.\{-}\)\s*$', '\1', '')
endfunction


function! pypi#Pypi(package)

    let request_uri = 'https://pypi.python.org/simple/'.s:Strip(a:package)
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


function! pypi#PypiReviewSearch(force)

    let filename = expand('%:t')

    if a:force || filename =~ 'requirement' || len(readfile(expand('%:p'))) < 20
        let search_packages = readfile(expand('%:p'))
    else
        echomsg 'Only first 20 lines would be searched. Use PypiReviewForce to check all lines.'
        let search_packages = readfile(expand('%:p'))[:20]
    endif

    for line in search_packages
        if line !~ '#' && strlen(line)
            try
                if line =~ '=='
                    let package_name = split(line, '==')[0]
                else
                    let package_name = line
                endif

                let latest_version = pypi#Pypi(package_name)
                if strlen(latest_version) > 0
                    echo latest_version
                endif
            catch
            endtry
        endif
    endfor

endfunction
