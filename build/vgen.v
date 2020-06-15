module build

import os

pub fn (mut parser Parser) create_v_file(out string) {
	prefix := 'V.'
	str_bracket := '\''
	mut lines := []string{}

	//V module
	lines << 'module main'

	//C Include
	for include in parser.includes {
		lines << include
	}

	lines << ''

	//Typedef
	for def in parser.defs {

		mut typ := def.to

		if check_prefix(prefix, typ) {
			typ = replace_prefix(prefix, typ)
			lines << 'type X__$def.name = $typ'
		} else {
			if def.name != 'void' {
				lines << 'type X__$def.name = X__$typ'
			}
		}
	}

	lines << ''

	for impl in parser.function_implementations {
		func := impl.function

		retval := func.return_val
		name := func.name.to_lower()
		mut params := ''
		if func.parameter.len > 0 {
			for param in func.parameter {
				params += ' $param.name X__$param.typ.name,'
			}
			params = params.substr(0, params.len - 1)
		}
		if retval != 'void' {
			lines << ' fn x__$name ($params) X__$retval {'
		} else {
			lines << ' fn x__$name ($params) {'
		}
		for line in impl.code {
			match parse_line(line) {
				.function_call {
					function, parameter := impl.parse_function(line, parser, prefix, str_bracket, 'x') or { panic(err) }
					mut param := ''
					if parameter.len > 0 {
						for par in parameter {
							param += par + ','
						}
						param = param.substr(0, param.len - 1)
					}
					if check_prefix(prefix, function.name) {
						n := replace_prefix(prefix, function.name)
						lines << '	${n} ($param)'
					} else {
						lines << '	x__$function.name ($param)'
					}
				}
				.definition {
					vname, variable, overwrite := impl.parse_definition(line, parser, prefix, str_bracket, 'x') or { panic(err) }
					impl.variables[vname] = variable
					if overwrite {
						lines << '	mut $vname = $variable.data'
					} else {
						lines << '	$vname := $variable.data'
					}
				}
				.return_call {
					raw, cast, to, primitive := impl.parse_return(line, parser, prefix, str_bracket, 'x') or { panic(err) }

					mut cast_expr := ''

					if cast {
						if check_prefix(prefix, to) {
							n := replace_prefix(prefix, to)
							cast_expr = 'as ${n}' 
						} else {
							cast_expr = 'as x__${to}'
						}


					}
					if check_prefix(prefix, raw) {
						n := replace_prefix(prefix, raw)
						lines << '	return $n $cast_expr'
					} else {
						if primitive {
							lines << '	return $raw $cast_expr'
						} else {
							lines << '	return x__$raw $cast_expr'
						}
					}
				}
				else {}
			}
		}
		lines << '}'
		lines << ''
	}

	lines << 'fn main() {'
	lines << '	x__main()'
	lines << '}'

	mut all := ''
	for line in lines {
		all = all + line + '\n'
	}

	os.write_file(out, all)
}
