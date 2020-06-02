module build

import os

pub fn (parser Parser) create_c_file(out string) {
	mut lines := []string{}

	//C Include

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