module build

import os

struct Import {
	path string
	parser Parser
}

struct Defenition {
	name string
	to string
}

struct Function {
	name string
	return_val string
	parameter []string
}

struct Parser {
mut:
	imports []Import
	defs []Defenition
	functions []Function
}

fn parse(file string) Parser {
	content := os.read_file(file) or { panic(err) }
	lines := content.trim_space().split('\n')
	for line, i in lines {
		data := line.split(' ')
		match data[0] {
			'use' {
				if data[1].starts_with('<') && data[1].ends_with('>') {
					//lib
				} else if data[1].starts_with('\'') && data[1].ends_with('\'') || data[1].starts_with('"') && data[1].ends_with('"') {
					//local
				} else {
					//error
				} 

			}
			'def' {

			}
			'fn' {

			}
		}
	}
}