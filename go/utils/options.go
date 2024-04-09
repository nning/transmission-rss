package utils

type Option struct {
	Active bool
	Value  string
}

type OptionMap map[rune]Option

type Options struct {
	options OptionMap
	Rest    []string
}

func ParseOptions(args []string) *Options {
	args = args[1:]
	options := make(OptionMap)
	rest := Slice[string](args).Clone()

	for i, a := range args {
		if a[0] == '-' && len(a) > 1 {
			for _, c := range a[1:] {
				options[c] = Option{true, ""}
			}
			rest = rest.DeleteValue(a)
		} else if len(args) > 1 {
			prev := args[i-1]
			if i-1 >= 0 && prev[0] == '-' && len(prev) > 1 {
				options[rune(prev[len(prev)-1])] = Option{true, a}
				rest = rest.DeleteValue(a)
			}
		}
	}

	return &Options{options, rest}
}

func (o *Options) IsSet(option rune) bool {
	return o.options[option] != Option{} && o.options[option].Active
}

func (o *Options) Get(option rune) string {
	return o.options[option].Value
}
