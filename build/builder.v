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
	parser := parse('$mod.path/$mod.main')
	parser.create_c_file(builder.output)
}
