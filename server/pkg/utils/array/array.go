package array

// UniqueInt64 returns unique elements in the input array
func UniqueInt64(input []int64) []int64 {
	visited := map[int64]bool{}
	var result []int64
	for _, value := range input {
		// check if already the mapped
		// variable is set to true or not
		if !visited[value] {
			visited[value] = true
			// Append to result slice.
			result = append(result, value)
		}
	}
	return result
}

// ContainsDuplicateInInt64Array returns true if the array contains duplicate elements.
func ContainsDuplicateInInt64Array(input []int64) bool {
	visited := map[int64]bool{}
	for _, value := range input {
		if visited[value] {
			return true
		}
		visited[value] = true
	}
	return false
}

// StringInList returns true is given string is present inside list
func StringInList(a string, list []string) bool {
	for _, b := range list {
		if b == a {
			return true
		}
	}
	return false
}

// int64InList returns true is given int64 is present inside list
func Int64InList(a int64, list []int64) bool {
	for _, b := range list {
		if b == a {
			return true
		}
	}
	return false
}
