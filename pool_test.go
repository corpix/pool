package pool

// The MIT License (MIT)
//
// Copyright © 2017 Dmitry Moskowski
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import (
	"github.com/stretchr/testify/assert"
	"sync"
	"testing"
	"time"
)

func TestPoolParallel(t *testing.T) {
	p := New(10, 10)
	defer p.Close()

	tasks := 10
	sleep := 1 * time.Second

	w := &sync.WaitGroup{}
	w.Add(tasks)

	started := time.Now()
	for n := 0; n < tasks; n++ {
		p.Feed <- func() {
			time.Sleep(sleep)
			w.Done()
		}
	}
	w.Wait()
	finished := time.Now()

	assert.False(t, started.Add(2*time.Second).Before(finished))
}

func TestPoolParallelQueue(t *testing.T) {
	p := New(10, 10)
	defer p.Close()

	tasks := 20
	sleep := 1 * time.Second

	w := &sync.WaitGroup{}
	w.Add(tasks)

	started := time.Now()
	lockedTimes := 0
	for n := 0; n < tasks; n++ {
		work := func() {
			time.Sleep(sleep)
			w.Done()
		}
		select {
		case p.Feed <- work:
		default:
			lockedTimes++
		}
	}
	w.Add(-lockedTimes)
	w.Wait()
	finished := time.Now()

	assert.False(t, started.Add(2*time.Second).Before(finished))
	assert.Equal(t, 10, lockedTimes)
}
