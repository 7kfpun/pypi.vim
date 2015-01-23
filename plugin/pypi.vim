" pypi - Get the latest version of the package in Vim
" Maintainer: kf <7kfpun@gmail.com>

scriptencoding utf-8


if (exists("g:loaded_pypi") && g:loaded_pypi) || &cp
    finish
endif
let g:loaded_pypi = 1


silent! call webapi#json#decode('{}')
if !exists('*webapi#json#decode')
    echohl ErrorMsg | echomsg "checkip.vim requires webapi (https://github.com/mattn/webapi-vim)" | echohl None
    finish
endif


function! s:check_defined(variable, default)
    if !exists(a:variable)
        let {a:variable} = a:default
    endif
endfunction

call s:check_defined('g:enable_add_latest_version', 0)
call s:check_defined('g:try_first_n_lines', 20)


command! -nargs=1 Pypi :echo pypi#Pypi(<f-args>)
command! PypiReview :call pypi#PypiReviewSearch(0)
command! PypiReviewForce :call pypi#PypiReviewSearch(1)
command! PypiThis :echo pypi#Pypi(getline("."))
