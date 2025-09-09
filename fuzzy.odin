package main

import "core:bytes"
import "core:fmt"
import "core:os"
import "core:os/os2"
import "core:path/filepath"
import "core:strings"

fuzzy :: proc(search_dir: string) -> []string {
	r, w, err := os2.pipe()
	if err != nil {
		return []string{}
	}

	_, err = os2.process_start(
		{
			command = {"fd", "--type", "d", "--hidden", "--no-ignore", "'.+.git$'", "$HOME/code"},
			stdout = w,
		},
	)
	if err != nil {
		return []string{}
	}


	output, err2 := os2.read_entire_file(r, context.allocator)
	if err2 != nil {
		return []string{}
	}

	res, _ := strings.split_lines(string(output))
	return res
}
