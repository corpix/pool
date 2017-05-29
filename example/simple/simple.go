package main

import (
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
		p.Feed <- func(n int) func() {
			return func() {
				time.Sleep(sleep)
				w.Done()
				fmt.Printf("Finished work '%d'\n", n)
			}
		}(n)
	}

	w.Wait()
}
