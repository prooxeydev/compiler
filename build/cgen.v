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

		mut typ := def.to

		if def.to.starts_with('C.') || def.to.starts_with('c.') {
			typ = typ.replace('C.', '').replace('c.', '')
			lines << 'typedef $typ X__$def.name;'
		} else {
			lines << 'typedef X__$typ X__$def.name;'
		}
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

		lines << 'X__$retval X__$name ($params);'
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

		lines << 'X__$retval X__$name ($params) {'
		for line in impl.code {
			match parse_line(line) {
				.function_call {
					function, parameter := impl.parse_function(line, parser) or { panic(err) }
					mut param := ''
					if parameter.len > 0 {
						for par in parameter {
							param += par + ','
						}
						param = param.substr(0, param.len - 1)
					}
					if function.name.starts_with('C.') || function.name.starts_with('c.') {
						n := function.name.replace('C.', '').replace('c.', '')
						lines << '	${n} ($param);'
					} else {
						lines << '	X__$function.name ($param);'
					}
				}
				.definition {
					vname, variable, overwrite := impl.parse_definition(line, parser) or { panic(err) }
					impl.variables[vname] = variable
					if overwrite {
						lines << '	$vname = $variable.data;'
					} else {
						lines << '	X__$variable.typ.name $vname = $variable.data;'.replace('\'', '"')
					}
				}
				.return_call {
					raw, cast, to, primitive := impl.parse_return(line, parser) or { panic(err) }

					mut cast_expr := ''

					if cast {
						if to.starts_with('C.') || to.starts_with('c.') {
							n := to.replace('C.', '').replace('c.', '')
							cast_expr = '($n)' 
						} else {
							cast_expr = '(X__$to)'
						}
					}

					if raw.starts_with('C.') || raw.starts_with('c.') {
						n := raw.replace('C.', '').replace('c.', '')
						lines << '	return $cast_expr $n;'
					} else {
						if primitive {
							lines << '	return $cast_expr $raw;'
						} else {
							lines << '	return $cast_expr X__$raw;'
						}
					}
				}
				else {}
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