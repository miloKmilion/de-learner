import sys

import pandas as pd

print(sys.argv)

day = sys.argv[1]

print(pd.__version__)
print(f"Job Finished successfully for day: {day}")
