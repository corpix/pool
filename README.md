pool
----

[![Build Status](https://travis-ci.org/corpix/pool.svg?branch=master)](https://travis-ci.org/corpix/pool)

Simplest goroutine pool ever.

## Example
``` go
package main

import (
	"context"
	"fmt"
	"sync"
	"time"

	"github.com/corpix/pool"
)

func main() {
	p := pool.New(10, 10)
	defer p.Close()

	w := &sync.WaitGroup{}

	tasks := 10
	sleep := 1 * time.Second

	for n := 0; n < tasks; n++ {
		w.Add(1)
		p.Feed <- pool.NewWork(
			context.Background(),
			func(n int) pool.Executor {
				return func(ctx context.Context) {
					select {
					case <-ctx.Done():
					default:
						time.Sleep(sleep)
						fmt.Printf("Finished work '%d'\n", n)
					}
					w.Done()
				}
			}(n),
		)
	}

	w.Wait()
}
```

Output:

> Results may differ on your machine, order is not guarantied.

``` console
$ go run ./example/simple/simple.go
Finished work '6'
Finished work '9'
Finished work '7'
Finished work '5'
Finished work '4'
Finished work '8'
Finished work '2'
Finished work '0'
Finished work '3'
Finished work '1'
```

## License

MIT
