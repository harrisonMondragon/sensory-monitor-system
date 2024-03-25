import pandas as pd
import matplotlib.pyplot as plt

# Read the CSV file into a pandas DataFrame
df = pd.read_csv("example_activity_data_clean.csv")

# Convert Timestamp column to datetime
df['Timestamp'] = pd.to_datetime(df['Timestamp'])

# Plot for sound values
plt.figure(figsize=(10, 5))
plt.plot(df['Timestamp'], df['Current Sound Value'], color='black', label='Current Sound Value')
plt.plot(df['Timestamp'], df['Maximum Sound Threshold'], color='green', label='Max Sound Threshold')
plt.xlabel('Timestamp [s]')
plt.ylabel('Sound [dB]')
plt.title('Sound Values vs. Time')
plt.legend()
plt.grid(True)
plt.xticks(rotation=45)
plt.tight_layout()
plt.show()

# Plot for temperature values
plt.figure(figsize=(10, 5))
plt.plot(df['Timestamp'], df['Current Temperature Value'], color='black', label='Current Temperature')
plt.plot(df['Timestamp'], df['Minimum Temperature Threshold'], color='blue', label='Min Temperature Threshold')
plt.plot(df['Timestamp'], df['Maximum Temperature Threshold'], color='red', label='Max Temperature Threshold')
plt.xlabel('Timestamp [s]')
plt.ylabel('Temperature [°C]')
plt.title('Temperature Value vs. Time')
plt.legend()
plt.grid(True)
plt.xticks(rotation=45)
plt.tight_layout()
plt.show()
