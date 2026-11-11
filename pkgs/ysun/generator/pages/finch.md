---
title: Finch
description: A simple neural net framework and visualizer that uses genetic networks to train
created: 2023-09-15
updated: 2026-02-12
metas:
  go-import: ysun.co/finch git https://github.com/stepbrobd/finch.git
  go-source: ysun.co/finch https://github.com/stepbrobd/finch https://github.com/stepbrobd/finch/tree/master{/dir} https://github.com/stepbrobd/finch/blob/master{/dir}/{file}#L{line}
hidden: true
---

## Credit

Idea from Boltzmann Brain (deleted) by
[@pehringer](https://github.com/pehringer).

## Installation & Usage

With Go installed, you can install the tool by running the following command:

```shell
go get -u ysun.co/finch
```

To use as library, import the package:

```go
import "ysun.co/finch"
```

If you have a working Nix installation:

```shell
nix run github.com/stepbrobd/finch
```

Source code: <https://github.com/stepbrobd/finch>

## Running Finch

![Demo](/assets/static/img/finch.gif)

**Gates**:

`-input=2 -output=1 -hidden=2`

2 input neurons, 1 output neuron, 1 hidden layer with 2 neurons

`-population=128 -mutation=0.025`

128 individules in the population, with 2.5% mutation rate

`-example=./data/gates/input_data.csv -expected=./data/gates/{or,nor,xor}_label_data.csv`

dataset paths

```shell
finch -input=2 -output=1 -hidden=2 -population=128 -mutation=0.025 -example=./data/gates/input_data.csv -expected=./data/gates/{or,nor,xor}_label_data.csv
```

Remember to change which operation you want to run: OR, NOR, XOR.

**Math**:

`-input=20 -output=19 -hidden=6,6,6,6`

20 input neurons, 19 output neurons, 4 hidden layers with 6 neurons each

`-population=32768 -mutation=0.01`

32768 individules in the population, with 1% mutation rate

`-example=./data/math/add_input_data.csv -expected=./data/math/add_output_data.csv`

dataset paths

```shell
finch -input=20 -output=19 -hidden=6,6,6,6 -population=32768 -mutation=0.01 -example=./data/math/add_input_data.csv -expected=./data/math/add_output_data.csv
```

**MNIST**:

`-input=784 -output=10 -hidden=16,16`

784 input neurons (28x28 greyscale images), 10 output neurons (numbers 1-10), 2
hidden layers with 16 neurons each

`-population=4096 -mutation=0.1`

4096 individules in the population, with 10% mutation rate

`-example=./data/mnist/mnist_pixel_data_{32,64,128,256,512,1024,2048,4096,8192}.csv -expected=./data/mnist/mnist_label_data_{32,64,128,256,512,1024,2048,4096,8192}.csv`

dataset paths

```shell
finch -input=784 -output=10 -hidden=16,16 -population=4096 -mutation=0.1 -example=./data/mnist/mnist_pixel_data_{32,64,128,256,512,1024,2048,4096,8192}.csv -expected=./data/mnist/mnist_label_data_{32,64,128,256,512,1024,2048,4096,8192}.csv
```

Remember to change the size of MNIST dataset: 32, 64, 128, 256, 512, 1024, 2048,
4096, 8192.
