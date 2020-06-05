module build

import os

struct Defenition {
	name string
	to string
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
mut:
	function Function
	code []string
	variables map[string]Variable
}

struct Variable {
mut:
	data string
	typ Defenition
}

struct Parser {
mut:
	compile bool
	includes []string
	defs []Defenition
	functions []Function
	function_implementations []&FunctionImplementation
	errors []Error
}

struct Error {
mut:
	line int
	file_path string
	error_msg string
	str_line string
}

pub fn create_empty_parser() Parser {
	return Parser{
		compile: true
		includes: []string{}
		defs: []Defenition{}
		functions: []Function{}
		function_implementations: []&FunctionImplementation{}
		errors: []Error{}
	}
}

fn (mut parser Parser)parse(file string) {
	content := os.read_file(file) or { panic(err) }
	lines := content.trim_space().split_into_lines()
	mut open_brackets := 0
	mut open_func := 0
	mut fn_impl := &FunctionImplementation{}
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
						parser.parse(path)
						parser.parse(path.substr(0, path.len - 1))
					} else if (data[1].starts_with('\'') && data[1].ends_with('\'')) || (data[1].starts_with('"') && data[1].ends_with('"')) {
						//local
						name := data[1].replace('"', '').replace('"', '')
						if name == '' {
							parser.errors << Error{i, file, 'No file given', line}
							parser.compile = false
						}
						path := './$name'
						parser.parse(path)
						parser.parse(path.substr(0, path.len - 1))
					} else {
						//error
						parser.errors << Error{i, file, 'Syntax error: not used <> or ""/\'\'', line}
						parser.compile = false
					} 
				}
				'def' {
					mut after := line.replace(data[0] + ' ', '')
					def := after.trim_space().split('=>')
					if def.len > 1 {
						name := def[0].trim_space()
						to := def[1].trim_space()
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
								if params[0].split(' ')[0] != ')' {
									mut last_typ := ''
									mut end := false
									for param in params {
										par := param.substr(0, param.len - 1).trim_space().split(' ')
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
										func := Function{name, return_val, parameter}
										fn_impl = &FunctionImplementation{func, []string{}}
										if parser.check_func(func) {
											open_func += 1
										}
									} else {
										//error
										parser.errors << Error{i, file, 'Syntax error: Bracked wasn\'t closed', line}
										parser.compile = false
									}
								} else {
									func := Function{name, return_val, parameter}
									fn_impl = &FunctionImplementation{func, []string{}}
									if parser.check_func(func) {
										open_func += 1
									}								
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
										func := Function{name, return_val, parameter}
										if !parser.check_func(func) {
											parser.functions << func
										} else {
											//error
											parser.errors << Error{i, file, 'Duplicate method: `$name`', line}
											parser.compile = false											
										}
									} else {
										//error
										parser.errors << Error{i, file, 'Syntax error: Bracked wasn\'t closed', line}
										parser.compile = false
									}
								} else {
									func := Function{name, return_val, parameter}
									if !parser.check_func(func) {
										parser.functions << func
									} else {
										//error
										parser.errors << Error{i, file, 'Duplicate method: `$name`', line}
										parser.compile = false											
									}								
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
				'#include' {
					parser.includes << line
				}
				else {
					if open_func > 0 {
						src := line.trim_space()
						if src.contains('}') {
							open_func -= 1
							if open_func == 0 {
								parser.function_implementations << fn_impl
								fn_impl = &FunctionImplementation{}
							}
						} else {
							fn_impl.code << src
						}
					}
				}
			}
		}
	}
}

fn (parser Parser) write_errors() {
	for error in parser.errors {
		println('---------------------------------------------------')
		println('$error.file_path:${error.line + 1}: error: $error.error_msg')
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

fn (parser Parser) check_func_exists(name string) bool {
	filter := parser.functions.filter(name == it.name)
	return filter.len == 1
}

fn (parser Parser) get_func(name string) Function {
	filter := parser.functions.filter(name == it.name)
	return filter[0]
}

fn (func Function) check_parameter(name string) bool {
	filter := func.parameter.filter(name == it.name)
	return filter.len == 1
}

fn (impl FunctionImplementation) check_variable(name string) bool {
	return name in impl.variables
}

fn (impl FunctionImplementation) get_variable(name string) Variable {
	return impl.variables[name]
}