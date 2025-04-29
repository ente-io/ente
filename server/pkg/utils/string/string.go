package string

// EmptyIfNil returns either the dereferenced string, or "" if the pointer is
// nil.
func EmptyIfNil(sp *string) string {
	if sp == nil {
		return ""
	}
	return *sp
}
