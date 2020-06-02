module build

import os

struct Import {
	path string
	parser Parser
}

struct Defenition {
	name string
	to []string
}

struct Parameter {
	name string
	typ Defenition
}

struct Function {
	name string
	return_val string
	parameter []Parameter
}

struct FunctionImplementation {
	function Function
	code []string
}

struct Parser {
mut:
	compile bool
	imports []Import
	defs []Defenition
	functions []Function
	function_implementations []FunctionImplementation
	errors []Error
}

struct Error {
mut:
	line int
	file_path string
	error_msg string
	str_line string
}

fn parse(file string) Parser {
	mut parser := Parser{
		compile: true
		imports: []Import{}
		defs: []Defenition{}
		functions: []Function{}
		function_implementations: []FunctionImplementation{}
		errors: []Error{}
	}
	content := os.read_file(file) or { panic(err) }
	lines := content.trim_space().split_into_lines()
	mut open_brackets := 0
	mut open_func := 0
	for i, line in lines {
		if line != '' {
			data := line.split(' ')
			match data[0] {
				'use' {
					if data[1].starts_with('<') && data[1].ends_with('>') {
						//lib
						name := data[1].replace('<', '').replace('>', '')
						if name == '' {
							parser.errors << Error{i, file, 'No file given', line}
							parser.compile = false
						}
						path := './lib/$name'
						tmp := parse(path)
						parser.imports << Import{path, tmp}
					} else if data[1].starts_with('\'') && data[1].ends_with('\'') || data[1].starts_with('"') && data[1].ends_with('"') {
						//local
						name := data[1].replace('"', '').replace('"', '')
						if name == '' {
							parser.errors << Error{i, file, 'No file given', line}
							parser.compile = false
						}
						path := './$name'
						tmp := parse(path)
						parser.imports << Import{path, tmp}
					} else {
						//error
						parser.errors << Error{i, file, 'Syntax error: not used <> or ""/\'\'', line}
						parser.compile = false
					} 
				}
				'def' {
					mut after := ''
					for d in data[1..] {
						after += d
					}
					def := after.trim_space().split('=>')
					if def.len > 1 {
						name := def[0]
						to := def[1].split(' ')
						if to.len == 0 {
							parser.errors << Error{i, file, 'Syntax error: nothing behind =>', line}
							parser.compile = false
						}
						if !parser.check_typ(name) {
							parser.defs << Defenition{name, to}
						} else {
							//error
							parser.errors << Error{i, file, 'Type already defined', line}
							parser.compile = false
						}
					} else {
						//error
						parser.errors << Error{i, file, 'Syntax error: nothing behind =>', line}
						parser.compile = false
					}
				}
				'fn' {
					mut after := line.replace(data[0] + ' ', '')
					if after.ends_with('{') {
						//Implementation
						mut return_val := 'void'
						if after.contains('<') {
							typ := after.split('<')[0]
							after = after.replace('$typ<', '')
							return_val = typ
						}
						if parser.check_typ(return_val) {
							fn_data := after.split('(')
							if fn_data.len == 2 {
								open_brackets += 1
								name := fn_data[0]
								mut parameter := []Parameter{}
								params := fn_data[1].split(',')
								mut last_typ := ''
								mut end := false
								for param in params {
									par := param.trim_space().split(' ')
									if par.len == 1 {
										if parser.check_typ(last_typ) {
											mut pname := par[0]
											if par[0].ends_with(')') {
												open_brackets -= 1
												end = true
												pname = pname.replace(')', '')
											}
											parameter << Parameter{pname, parser.get_typ(last_typ)}											
										} else {
											//error
											parser.errors << Error{i, file, 'Parameter type `$last_typ` doesn\'t exists', line}
											parser.compile = false
										}
									} else if par.len == 2 {
										last_typ = par[0]
										if parser.check_typ(last_typ) {
											mut pname := par[1]
											if par[1].ends_with(')') {
												open_brackets -= 1
												end = true
												pname = pname.replace(')', '')
											}
											parameter << Parameter{pname, parser.get_typ(last_typ)}											
										} else {
											//error
											parser.errors << Error{i, file, 'Parameter type `$last_typ` doesn\'t exists', line}
											parser.compile = false
										}
									} else {
										//error
										parser.errors << Error{i, file, 'Wrong amount of data, maybe you missed a `,`', line}
										parser.compile = false
									}
								}
								if end {
									function := Function{name, return_val, parameter}
									if parser.check_func(function) {
										println('contains')
									}
								} else {
									//error
									parser.errors << Error{i, file, 'Syntax error: Bracked wasn\'t closed', line}
									parser.compile = false
								}		
							} else {
								//error
								parser.errors << Error{i, file, 'Syntax error: Something went wrong', line}
								parser.compile = false
							}
						} else {
							parser.errors << Error{i, file, 'Return value type doesn\'t exists', line}
							parser.compile = false
						}
					} else {
						//FunctionDeclaration
						mut return_val := 'void'
						if after.contains('<') {
							typ := after.split('<')[0]
							after = after.replace('$typ<', '')
							return_val = typ
						}
						if parser.check_typ(return_val) {
							fn_data := after.split('(')
							if fn_data.len == 2 {
								open_brackets += 1
								name := fn_data[0]
								mut parameter := []Parameter{}
								params := fn_data[1].split(',')
								if params[0] != ')' {
									mut last_typ := ''
									mut end := false
									for param in params {
										par := param.trim_space().split(' ')
										if par.len == 1 {
											if parser.check_typ(last_typ) {
												mut pname := par[0]
												if par[0].ends_with(')') {
													open_brackets -= 1
													end = true
													pname = pname.replace(')', '')
												}
												parameter << Parameter{pname, parser.get_typ(last_typ)}											
											} else {
												//error
												parser.errors << Error{i, file, 'Parameter type `$last_typ` doesn\'t exists', line}
												parser.compile = false
											}
										} else if par.len == 2 {
											last_typ = par[0]
											if parser.check_typ(last_typ) {
												mut pname := par[1]
												if par[1].ends_with(')') {
													open_brackets -= 1
													end = true
													pname = pname.replace(')', '')
												}
												parameter << Parameter{pname, parser.get_typ(last_typ)}											
											} else {
												//error
												parser.errors << Error{i, file, 'Parameter type `$last_typ` doesn\'t exists', line}
												parser.compile = false
											}
										} else {
											//error
											parser.errors << Error{i, file, 'Wrong amount of data, maybe you missed a `,`', line}
											parser.compile = false
										}
									}
									if end {
										parser.functions << Function{name, return_val, parameter}
									} else {
										//error
										parser.errors << Error{i, file, 'Syntax error: Bracked wasn\'t closed', line}
										parser.compile = false
									}
								} else {
									parser.functions << Function{name, return_val, parameter}									
								}	
							} else {
								//error
								parser.errors << Error{i, file, 'Syntax error: Something went wrong', line}
								parser.compile = false
							}
						} else {
							parser.errors << Error{i, file, 'Return value type doesn\'t exists', line}
							parser.compile = false
						}
					}
				}
				else {

				}
			}
		}
	}
	for im in parser.imports {
		if !im.parser.compile {
			parser.compile = false
		}
		parser.errors << im.parser.errors
		parser.defs << im.parser.defs
		parser.functions << im.parser.functions
	}
	return parser
}

fn (parser Parser) write_errors() {
	for error in parser.errors {
		println('---------------------------------------------------')
		println('$error.file_path:$error.line: error: $error.error_msg')
		println(error.str_line)
	}
}

fn (parser Parser) check_typ(name string) bool {
	filter := parser.defs.filter(name == it.name)
	return filter.len == 1
}

fn (parser Parser) get_typ(name string) Defenition {
	filter := parser.defs.filter(name == it.name)
	return filter[0]
} 

fn (parser Parser) check_func(func Function) bool {
	mut ret := false
	for fun in parser.functions {
		if func.name == fun.name {
			if func.return_val == fun.return_val {
				for i := 0; i < func.parameter.len; i++ {
					if func.parameter[i].typ.name != fun.parameter[i].typ.name {
						break
					}
				}
				ret = true
			}
		}
	}
	return ret
}