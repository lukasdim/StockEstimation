from matplotlib import pyplot as plt

from managers.managers import DataManager
from estimation.estimation import ShortEstimation, LongEstimation
import pandas

manager = DataManager()

manager.fetch_new_ticker("AAPL", auto_update=False)
manager.fetch_new_ticker("MSFT", auto_update=False)

manager.update_data()

forecaster = ShortEstimation(horizon=21, window_size=10)
long_forecaster = LongEstimation()
result = long_forecaster.estimate(manager.get_ticker_data("AAPL"))

print(result)
#must use get_ticker_data because it adds EPS data to dataframe to help with predictions
pred_price, real_price = forecaster.estimate(manager.get_ticker_data("AAPL"))
#must use update_preds function because the manager object is not connected to estimation function
#and cannot be done automatically
print(manager.update_preds("AAPL", pred_price))
print(manager.short_predictions)

# code below grabs prediction data automatically from short_predictions
#manager.short_predictions.index.get_level_values(1).unique().values
#ticker_data = manager.short_predictions.xs(ticker.upper(), axis=0, level=1)
plt.plot(range(len(result)), result["yhat"], marker='o', linestyle='-', color='g')
plt.plot(range(len(result)), result["yhat_lower"], marker='o', linestyle='-', color='b')
plt.plot(range(len(result)), result["yhat_upper"], marker='o', linestyle='-', color='b')
plt.plot(range(len(pred_price)), pred_price, marker='o', linestyle='-', color='r')
#plt.plot(len(real_price), real_price, marker='o', linestyle='-', color='b')
plt.xlabel('Date')
plt.ylabel('Close')
plt.grid()
plt.show()