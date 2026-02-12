import pandas as pd
import pyodbc
import nltk  # обработка языка
from nltk.sentiment.vader import SentimentIntensityAnalyzer  # анализатор настроений


# Получение данных из SQL Server
def fetch_data_from_sql():
    conn_str = (
        "Driver={SQL Server};"
        "Server=LAPTOP-7GGL8BL1;"
        "Database=PortfolioProject_MarketingAnalytics;"
        "Trusted_Connection=yes;"
    )

    conn = pyodbc.connect(conn_str)

    query = "SELECT ReviewID, CustomerID, ProductID, ReviewDate, Rating, ReviewText from customer_reviews"

    df = pd.read_sql(query, conn)

    conn.close()

    return df


customer_reviews_df = fetch_data_from_sql()

sia = SentimentIntensityAnalyzer()


# Функция для расчета настроения текста
def calculate_sentiment(review):
    # Получение оценок настроения для текста отзыва
    sentiment = sia.polarity_scores(review)
    # Возвращаем compound-оценку (нормированная от -1 до 1)
    return sentiment['compound']


# Функция для категоризации настроений с учетом оценки 
def categorize_sentiment(score, rating):
    # Положительная тональность текста
    if score > 0.05:
        if rating >= 4:
            return 'Positive'  # Высокая оценка и положительный текст
        elif rating == 3:
            return 'Mixed Positive'  # Нейтральная оценка, но положительный текст
        else:
            return 'Mixed Negative'  # Низкая оценка, но положительный текст

    # Отрицательные настроения текста
    elif score < -0.05:
        if rating <= 2:
            return 'Negative'  # Низкая оценка и отрицательный текст
        elif rating == 3:
            return 'Mixed Negative'  # Нейтральная оценка, но отрицательный текст
        else:
            return 'Mixed Positive'  # Высокая оценка, но отрицательный текст

    # Нейтральные настроения текста
    else:
        if rating >= 4:
            return 'Positive'  # Высокая оценка при нейтральном тексте
        elif rating <= 2:
            return 'Negative'  # Низкая оценка при нейтральном тексте
        else:
            return 'Neutral'  # Нейтральная оценка и нейтральный текст


# Функция для группировки оценок настроений в диапазоны
def sentiment_bucket(score):
    if score >= 0.5:
        return '0.5 to 1.0'  
    elif 0.0 <= score < 0.5:
        return '0.0 to 0.49'  
    elif -0.5 <= score < 0.0:
        return '-0.49 to 0.0' 
    else:
        return '-1.0 to -0.5' 


# Применение анализа настроений ко всем отзывам
customer_reviews_df['SentimentScore'] = customer_reviews_df['ReviewText'].apply(calculate_sentiment)

# Категоризация отзывов с учетом оценки и настроения текста
customer_reviews_df['SentimentCategory'] = customer_reviews_df.apply(
    lambda row: categorize_sentiment(row['SentimentScore'], row['Rating']), axis=1)

# Группировка оценки настроений в диапазоны
customer_reviews_df['SentimentBucket'] = customer_reviews_df['SentimentScore'].apply(sentiment_bucket)

print(customer_reviews_df.head())


customer_reviews_df.to_csv('fact_customer_reviews_with_sentiment.csv', index=False)
