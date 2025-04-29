package recover

import (
	"errors"
	"testing"
)

func TestInt64ToInt64RecoverWrapper(t *testing.T) {

	type args struct {
		input          int64
		fn             Int64ToInt64DataFn
		output         *int64
		expectedOutput int64
	}
	var expectedResult int64

	tests := []struct {
		name    string
		args    args
		wantErr bool
	}{
		{
			"success",
			args{input: 1, fn: func(userID int64) (int64, error) { return 5, nil }, output: &expectedResult, expectedOutput: 5},
			false,
		},
		{
			"err",
			args{input: 1, fn: func(userID int64) (int64, error) { return 0, errors.New("testErr") }, output: nil, expectedOutput: 0},
			true,
		},
		{
			"panic_err",
			args{input: 1, fn: func(userID int64) (int64, error) { panic("panic err") }, output: nil, expectedOutput: 0},
			true,
		},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			err := Int64ToInt64RecoverWrapper(tt.args.input, tt.args.fn, tt.args.output)
			if (err != nil) != tt.wantErr {
				t.Errorf("Int64ToInt64RecoverWrapper() error = %v, wantErr %v", err, tt.wantErr)
			}
			if err == nil {
				if *tt.args.output != tt.args.expectedOutput {
					t.Errorf("Int64ToInt64RecoverWrapper() output = %v, expectedOutput %v", *tt.args.output, tt.args.expectedOutput)
				}
			}
		})
	}
}
