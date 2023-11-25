# NASDAQ ITCH 5.0 Running VWAP Calculater

Calculate the running Volume weighted average price(VWAP) of each stock at all trading hours given the NASDAQ ITCH 5.0 tick data file.

The program will print the execution time at the end.

### Output

`/out` folder has VWAP results for each trading hour, and the files are named by the timestamp


### Prerequisites

Python 3.5

Cython==0.28.5

### Running 

Navigate to the VWAP directory and run the following commands in your terminal.


```
pip install -r requirements.txt
mkdir out
python setup.py build_ext --inplace
python main.py [itch_file_path] 
```

If ITCH file path is not provided, the program will look up for the file in the current working directory

### Performance

Machine: MacBook Pro (13-inch, 2017)

Processor: 2.3 GHz Intel Core i5

Memory: 16 GB 2133 MHz LPDDR3

real	20m3.138s

user	18m37.068s

sys	0m29.306s
