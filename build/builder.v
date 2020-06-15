module build

import os

struct Builder {
mut:
	mod XMod
	output string
	exec string
}

pub fn build(path string, args []string) {
	mut builder := Builder{}
	mod := parse_x_mod(path)
	builder.mod = mod
	builder.output = '$path/tmp'
	builder.exec = '$path/a.out'
	mut parser := create_empty_parser()

	mut backend := ''

	if '-v' in args {
		backend = 'v'
	}

	parser.parse('$mod.path/$mod.main', backend)
	parser.write_errors()

	if '-v' !in args {
		parser.create_c_file('${builder.output}.c')
		mut cargs := ''

		if '-cwarns' !in args {
			cargs += '-w '
		}

		os.system('gcc ${builder.output}.c -o $builder.exec $cargs')
		os.system('./$builder.exec')

		if '-keepc' !in args {
			os.rm(builder.output)
		}

		os.rm(builder.exec)
	} else {
		parser.create_v_file('${builder.output}.v')
	}
}

fn check_prefix(prefix, expr string) bool {
	return expr.starts_with(prefix) || expr.starts_with(prefix.to_lower())	
}

fn replace_prefix(prefix, expr string) string {
	return expr.replace(prefix, '').replace(prefix.to_lower(), '')
}

fn is_string(expr string) bool {
	return expr.starts_with('\'') && expr.ends_with('\'')
}

fn make_string(brackets, expr string) string {
	if brackets != '\'' {
		return expr.replace('\'', brackets)
	}
	return expr
}