package config

func DefaultString(val string, defaultValue string) string {
	if len(val) == 0 {
		return defaultValue
	}

	return val
}

func DefaultInt(val int, defaultValue int) int {
	if val == 0 {
		return defaultValue
	}

	return val
}
