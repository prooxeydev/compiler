module build

struct Builder {
mut:
	mod XMod
	output string
}

pub fn build(path string, args []string) {
	mut builder := Builder{}
	mod := parse_x_mod(path)
	builder.mod = mod
	builder.output = '$path/tmp.c'
	mut parser := create_empty_parser()
	parser.parse('$mod.path/$mod.main')
	parser.write_errors()
	parser.create_c_file(builder.output)
}
