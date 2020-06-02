module build

import os

pub fn (mut parser Parser) create_c_file(out string) {
	mut lines := []string{}

	//C Include
	for include in parser.includes {
		lines << include
	}

	lines << ''

	//Typedef
	for def in parser.defs {
		to := def.to[0]

		mut typ := to

		if to.starts_with('C.') || to.starts_with('c.') {
			typ = typ.replace('C.', '').replace('c.', '')
		}
		lines << 'typedef $typ X__$def.name;'
	}

	lines << ''

	for func in parser.functions {
		retval := func.return_val
		name := func.name
		mut params := ''
		if func.parameter.len > 0 {
			for param in func.parameter {
				params += 'X__$param.typ.name $param.name,'
			}
			params = params.substr(0, params.len - 1)
		}

		lines << '$retval X__$name ($params);'
	}

	lines << ''

	for impl in parser.function_implementations {
		func := impl.function

		retval := func.return_val
		name := func.name
		mut params := ''
		if func.parameter.len > 0 {
			for param in func.parameter {
				params += 'X__$param.typ.name $param.name,'
			}
			params = params.substr(0, params.len - 1)
		}

		lines << '$retval X__$name ($params) {'
		for line in impl.code {
			match parse_line(line) {
				.function_call {
					function, parameter := parser.parse_function(line) or { panic(err) }
					mut param := ''
					for par in parameter {
						param += par + ','
					}
					param = param.substr(0, param.len - 1)
					if function.name.starts_with('C.') || function.name.starts_with('c.') {
						n := function.name.replace('C.', '').replace('c.', '')
						lines << '	${n} ($param);'
					} else {
						lines << '	X__$function.name ($param);'
					}
				}
				.definition {

				}
				.math {

				}
			}
		}
		lines << '}'
		lines << ''
	}

	lines << 'int main() {'
	lines << '	X__main();'
	lines << '	return 0;'
	lines << '}'

	mut all := ''
	for line in lines {
		all = all + line + '\n'
	}

	os.write_file(out, all)
}