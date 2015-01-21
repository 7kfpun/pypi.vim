" pypi - Get the latest version of the package in Vim
" Maintainer: kf <7kfpun@gmail.com>


silent! call webapi#json#decode('{}')
if !exists('*webapi#json#decode')
    echohl ErrorMsg | echomsg "checkip.vim requires webapi (https://github.com/mattn/webapi-vim)" | echohl None
    finish
endif


function! Pypi(package)
    let request_uri = 'https://pypi.python.org/simple/'.a:package
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
            echo latest_version
            return latest_version
        catch
            echomsg 'Package could not be found.'
        endtry

    catch
        echoerr 'Something wrong with the internet.'
    endtry

endfunction

command! -nargs=1 Pypi call Pypi(<f-args>)
