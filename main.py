from managers.managers import DataManager

manager = DataManager()

apl = manager.fetch_new_ticker("AAPL") # auto_update returns only AAPL stocks
manager.fetch_new_ticker("AMZN", False)

manager.update_data()

print(manager.data.head())