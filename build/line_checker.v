module build

enum Typ {
	function_call
	definition
	math
	return_call
	nothing
	primitive
}

pub fn parse_line(line string) Typ {
	if line.starts_with('return') {
		return .return_call
	} else if line.contains('=') {
		return .definition
	} else if line.contains('(') && line.contains(')') {
		//function call
		return .function_call
	} else if line.starts_with('\'') && line.ends_with('\'') {
		return .primitive
	} else {
		return .nothing
	}
}

pub fn (impl FunctionImplementation) parse_function(line string, parser Parser, prefix, str_bracket, kprefix string) ?(Function, []string) {
	data := line.split_nth('(', 2)
	name := data[0]
	mut parameter := []string{}

	mut last := []byte{}
	mut str := false

	mut open_b := 0
	for b in data[1] {
		if b == '\''.bytes()[0] {
			if str {
				str = false
			} else {
				str = true
			}
		}
		if b == '('.bytes()[0] {
			open_b += 1
		}
		if b == ')'.bytes()[0] {
		}
		if b == ','.bytes()[0] {
			if !str {
				if last.len > 0 {
					parameter << string(last)
					last = []byte{}
				}
			}
		} else if b == ')'.bytes()[0] {
			if !str {
				if last.len > 0{
					if open_b > 0 {
						open_b -= 1
						last << ')'.bytes()[0]
					}
					if open_b == 0 {
						parameter << string(last)
						last = []byte{}
					}
				}
			}
		} else {
			last << b
		}
	}

	if parser.check_func_exists(name) {
		func := parser.get_func(name)
		if func.parameter.len == parameter.len {
			for i := 0; i < func.parameter.len; i++ {
				match func.parameter[i].typ.name {
					'string' {
						typ := parse_line(parameter[i].trim_space())

						match typ {
							.primitive {
								parameter[i] = make_string(str_bracket, parameter[i])
							}
							.nothing {
								if !impl.check_variable(parameter[i].trim_space()) {
									return error('Variable doesn\'t exists.')
								}
								parameter[i] = parameter[i].trim_space()

							}
							.function_call {
								function, param_val := impl.parse_function(parameter[i].trim_space(), parser, prefix, str_bracket, kprefix) or { panic(err) }
								mut param := ''
								if param_val.len > 0 {
									for par in param_val {
										param += par + ','
									}
									param = param.substr(0, param.len - 1)
								}

								if check_prefix(prefix, function.name) {
									n := replace_prefix(prefix, function.name)
									parameter[i] = '$n ($param)'
								} else {
									parameter[i] = '${kprefix}__$function.name ($param)'
								}

							}
							else {}
						}
					}
					else {
						//Parameter
					}
				}
			}
			return func, parameter
		} else {
			//error
			return error('Not enought parameter ($parameter.len given but needs $func.parameter.len)')
		}
	} else if check_prefix(prefix, name) {
		for i, _ in parameter {
			parameter[i] = make_string(str_bracket, parameter[i])
		}
		return Function{name}, parameter
	} else {
		println(name)
		//error
		return error('Function doesnt exists')
	}
}

pub fn (impl FunctionImplementation) parse_definition(line string, parser Parser, prefix, str_bracket, kprefix string) ?(string, Variable, bool) {
	mut name := ''
	mut name_buf := []byte{}
	mut data := ''
	mut data_buf := []byte{}
	mut def := false 
	for b in line.bytes() {
		if !def {
			if b != 32 {
				if b != 61 {
					name_buf << b
				} else if b == 61 {
					name = string(name_buf)
					def = true
				}
			}
		} else {
			if b != 32 {
				data_buf << b
			}
		}
	}
	data = string(data_buf)
	mut data_typ := ''
	line_typ := parse_line(data)

	match line_typ {
		.function_call {
			func, _ := impl.parse_function(data, parser, prefix, str_bracket, kprefix) or { panic(err) }
			data_typ = func.return_val
			if !check_prefix(prefix, data) {
				data = '${kprefix}__$data'
			}
		}
		.primitive {
			if data.starts_with('\'') && data.ends_with('\'') {
				//String
				data_typ = 'string'
				data = make_string(str_bracket, data)
			} else if data[0].is_digit() {
				//int
				data_typ = 'int'
			}
		}
		else {

		}
	}

	if !parser.check_typ(data_typ) {
		return error('Type doesnt exists')
	}

	typ := parser.get_typ(data_typ)
	variable := Variable{data, typ}

	mut overwrite := false

	if impl.check_variable(name) {
		v := impl.get_variable(name)
		if v.typ.name != typ.name {
			return error('Cannot change datatype')
		}
		overwrite = true
	}

	return name, variable, overwrite
}

pub fn (impl FunctionImplementation) parse_return(line string, parser Parser, prefix, str_bracket, kprefix string) ?(string, bool, string, bool) {
	mut parameter := []string{}

	mut last := []byte{}
	mut str := false

	for b in line.replace('return', '').trim_space() {
		if b == '\''.bytes()[0] {
			if str {
				str = false
			} else {
				str = true
			}
		}
		if b == ' '.bytes()[0] {
			if !str {
				if last.len > 0 {
					parameter << string(last)
					last = []byte{}
				}
			}
		} else {
			last << b
		}
	}
	parameter << string(last)

	mut ret_data := parameter[0]
	ret_data_type := parse_line(ret_data)

	mut cast := false
	mut to := ''
	mut primitive := false

	match ret_data_type {
		.function_call {
			function, _ := impl.parse_function(ret_data, parser, prefix, str_bracket, kprefix) or { panic(err) }
			if parameter.len < 2 {
				if (impl.function.return_val != function.return_val) && !check_prefix(prefix, function.name) {
					return error('Wrong return value type')
				}
			} else {
				cast = parameter[1] == 'as'
				to = parameter[2]
			}
		}
		.nothing {
			if !impl.function.check_parameter(ret_data) {
				return error('Wrong return argument')
			}
			primitive = true
			/*if parameter.len < 2 {
				cast = parameter[1] == 'as'
				to = parameter[2]
			}*/
		}
		.primitive {
			primitive = true
			mut data_typ := ''

			if ret_data.starts_with('\'') && ret_data.ends_with('\'') {
				//String
				data_typ = 'string'
				ret_data = make_string(str_bracket, ret_data)
			} else if ret_data[0].is_digit() {
				//int
				data_typ = 'int'
			} else {
				//Struct or other
				data_typ = ''
			}
			if parameter.len < 2 {
				if impl.function.return_val != data_typ {
					return error('Wrong return value type')
				}
			} else {
				cast = parameter[1] == 'as'
				to = parameter[2]
			}

		}
		else {
			return error('Something went wrong (ERROR: 0x00001)')
		}
	}

	return ret_data, cast, to, primitive

}