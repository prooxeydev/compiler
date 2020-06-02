module build

enum Typ {
	function_call
	definition
	math
}

pub fn parse_line(line string) Typ {
	if line.contains('(') && line.contains(')') {
		//function call
		return .function_call
	} else if line.contains('=') {
		return .definition
	}
}

pub fn (impl FunctionImplementation) parse_function(line string, parser Parser) ?(Function, []string) {
	data := line.split('(')
	name := data[0]
	mut parameter := []string{}

	mut last := []byte{}
	mut str := false

	for b in data[1] {
		if b == '\''.bytes()[0] {
			if str {
				str = false
			} else {
				str = true
			}
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
				if last.len > 0 {
					parameter << string(last)
					last = []byte{}
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
						isvar := impl.check_variable(parameter[i]) && impl.get_variable(parameter[i]).typ.name == 'string'
						rawstring := parameter[i].trim_space().starts_with('\'') && parameter[i].trim_space().ends_with('\'')

						if !isvar && !rawstring {
							return error('String isnt given')
						}
						if rawstring {
							parameter[i] = parameter[i].trim_space().replace('\'', '"')
						} else if isvar {
							parameter[i] = parameter[i].trim_space()
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
	} else if name.starts_with('C.') || name.starts_with('c.') {
		for i, _ in parameter {
			parameter[i] = parameter[i].trim_space().replace('\'', '"')
		}
		return Function{name}, parameter
	} else {
		//error
		return error('Function doesnt exists')
	}
}

pub fn (impl FunctionImplementation) parse_definition(line string, parser Parser) ?(string, Variable, bool) {
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

	if data.starts_with('\'') && data.ends_with('\'') {
		//String
		data_typ = 'string'
		data = data.replace('\'', '"')
	} else if data[0].is_digit() {
		//int
		data_typ = 'int'
	} else {
		//Struct or other
		data_typ = ''
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