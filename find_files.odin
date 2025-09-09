package main

import "core:bytes"
import "core:fmt"
import "core:os/os2"
import "core:path/filepath"
import "core:strings"


find_files :: proc(search_dir: string) -> []string {

	r, w, err := os2.pipe()
	defer os2.close(r)
	if err != nil {
		fmt.println(err)
		return []string{}
	}

	p: os2.Process;{
		defer os2.close(w)

		pr, err3 := os2.process_start(
			{command = {`fd`, `--hidden`, `'^\.git$'`, `/home/djaap/code`}, stdout = w},
		)
		if err3 != nil {
			fmt.println(err3)
			return []string{}
		}
		fmt.println(pr)
	}


	output, err2 := os2.read_entire_file(r, context.allocator)
	fmt.println("output: ", string(output))
	if err2 != nil {
		fmt.println("fail to read", err)
		return []string{}
	}


	res, _ := strings.split_lines(string(output))
	fmt.println("result", res)
	return res
}
