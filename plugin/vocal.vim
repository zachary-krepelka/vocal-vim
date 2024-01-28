" FILENAME: vocal.vim
" AUTHOR: Zachary Krepelka
" DATE: Saturday, January 20th, 2024
" ORIGIN: https://github.com/zachary-krepelka/vocal-vim
" UPDATED: Saturday, January 27th, 2024 at 9:15 PM

" Variables {{{1

if exists("g:loaded_vocal_vim")

	finish

endif

let g:loaded_vocal_vim = 1

if !exists('g:speaker')

	" This variable specifies the
	" external speech synthesizer.

	let g:speaker = 'espeak'

endif

if !exists('g:speaker_notes')

	" When this variable is flagged,
	" echo the spoken text.

	let g:speaker_notes = 0

endif

if !exists('g:speaker_instructions')

	" This variable specifies the arguments
	" passed to the external speech synthesizer.

	let g:speaker_instructions = ''

endif

" Functions {{{1

function! Speak(type = '') abort

	if a:type == ''

		" Set up the function to receive a motion

		set opfunc=Speak

		return 'g@'

	endif

	let l:speech = ''

	if index(['char', 'line', 'block'], a:type) == -1

		" This is reached when the function is
		" manually called by the user.

		let l:speech = a:type

	else

		" This is reached when the function is
		" called as part of a motion.

		let l:save = {
		\	'clipboard'    : &clipboard,
		\	'selection'    : &selection,
		\	'register'     : getreginfo('"'),
		\	'visual_marks' : [getpos("'<"), getpos("'<")],
		\ }

		try

			set clipboard= selection=inclusive

			let l:command = {
			\	'char'  : "`[v`]y",
			\	'line'  : "'[V']y",
			\	'block' : "gvy",
			\ }[a:type]

			execute
			\
			\	'silent '    ..
			\	'noautocmd ' ..
			\	'keepjumps ' ..
			\	'normal! '   ..
			\	l:command

			let l:speech = getreg('"')

		finally

			let  &clipboard = l:save.clipboard
			let  &selection = l:save.selection
			call setreg('"' , l:save.register)
			call setpos("'<", l:save.visual_marks[0])
			call setpos("'>", l:save.visual_marks[1])

		endtry

	endif

	let l:speech = substitute(trim(l:speech), "'", "''", "g")

	call system(
	\
	\ 	g:speaker              ..
	\ 	" "                    ..
	\ 	g:speaker_instructions ..
	\ 	" -- '"                ..
	\ 	l:speech               ..
	\ 	"' &"                   )

	" The -- signifies the end of command-line options.
	" The &  instructs the shell to run the command in the background.

	if g:speaker_notes

		echo l:speech

	endif

endfunction

" Commands {{{1

command -nargs=1 Speak :call Speak(<q-args>)

" Mappings {{{1

nnoremap <expr> gs  Speak()
xnoremap <expr> gs  Speak()
nnoremap <expr> gss Speak() .. '_'

" Menus {{{1

if has("gui_running") && has("menu") && &go =~# 'm'

	amenu <silent> &Plugin.Vocal\ Vim.&Help :tab help vocal-vim<CR>

endif
