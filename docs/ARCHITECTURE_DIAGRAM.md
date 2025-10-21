# 🏗️ Architecture Diagram - MarketDataStreamingService

## 📊 System Overview

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                           MarketDataStreamingService                            │
└─────────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────────────┐
│                              T-Invest API                                      │
│  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐            │
│  │   LastPrice     │    │      Trade      │    │   Instruments   │            │
│  │   Stream        │    │     Stream      │    │   (Shares +     │            │
│  │                 │    │                 │    │    Futures)     │            │
│  └─────────────────┘    └─────────────────┘    └─────────────────┘            │
└─────────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────────────┐
│                          gRPC Bidirectional Stream                             │
│  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐            │
│  │  HTTP/2         │    │  Protocol       │    │  Binary         │            │
│  │  Multiplexing   │    │  Buffers        │    │  Serialization  │            │
│  └─────────────────┘    └─────────────────┘    └─────────────────┘            │
└─────────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────────────┐
│                        Multi-threaded Processing                               │
│  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐            │
│  │  processLastPrice│    │   processTrade  │    │  insertTradeData│            │
│  │  (UTC+3 time)   │    │  (BUY/SELL)     │    │  Async()        │            │
│  └─────────────────┘    └─────────────────┘    └─────────────────┘            │
└─────────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────────────┐
│                            PostgreSQL Database                                  │
│  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐            │
│  │   invest.trades │    │  invest.shares  │    │ invest.futures  │            │
│  │                 │    │                 │    │                 │            │
│  │ Direction Types:│    │   Reference     │    │   Reference     │            │
│  │ • LAST_PRICE    │    │     Data        │    │     Data        │            │
│  │ • BUY           │    │                 │    │                 │            │
│  │ • SELL          │    │                 │    │                 │            │
│  └─────────────────┘    └─────────────────┘    └─────────────────┘            │
└─────────────────────────────────────────────────────────────────────────────────┘
```

## 🎯 Data Flow

### 1. **Instrument Loading**

```
getAllInstruments() → shares + futures → FIGI list
```

### 2. **Subscription Setup**

```
FIGI list → gRPC Stream → T-Invest API
```

### 3. **Data Processing**

```
T-Invest API → gRPC Stream → processLastPrice()/processTrade() → TradeEntity
```

### 4. **Database Storage**

```
TradeEntity → insertTradeDataAsync() → PostgreSQL (invest.trades)
```

## 📋 Direction Types Flow

### **LastPrice Processing:**

```
LastPrice → processLastPrice() → TradeEntity {
    direction: "LAST_PRICE"
    quantity: 1
    trade_source: "LAST_PRICE"
}
```

### **Trade Processing:**

```
Trade → processTrade() → TradeEntity {
    direction: "BUY" | "SELL"
    quantity: trade.getQuantity()
    trade_source: "EXCHANGE"
}
```

## ⚡ Performance Architecture

### **Thread Pools:**

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                              Thread Configuration                               │
│                                                                                 │
│  Trade Insert Threads: CPU_CORES * 6                                           │
│  Max Concurrent Inserts: 200                                                   │
│  Semaphore Control: tradeInsertSemaphore                                       │
│                                                                                 │
│  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐            │
│  │   Executor      │    │   Semaphore     │    │   Batch         │            │
│  │   Service       │    │   Control       │    │   Processing    │            │
│  └─────────────────┘    └─────────────────┘    └─────────────────┘            │
└─────────────────────────────────────────────────────────────────────────────────┘
```

### **Database Optimization:**

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                            Database Layer                                       │
│                                                                                 │
│  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐            │
│  │   UPSERT        │    │   Batch         │    │   Indexes       │            │
│  │   Operations    │    │   Processing    │    │   Optimization  │            │
│  │                 │    │                 │    │                 │            │
│  │ ON CONFLICT     │    │ 100+ records    │    │ figi, time,     │            │
│  │ DO UPDATE       │    │ per batch       │    │ direction       │            │
│  └─────────────────┘    └─────────────────┘    └─────────────────┘            │
└─────────────────────────────────────────────────────────────────────────────────┘
```

## 🔄 Reconnection Logic

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                            Reconnection Flow                                    │
│                                                                                 │
│  Error/Disconnect → scheduleReconnect() → Exponential Backoff → Restart Stream │
│                                                                                 │
│  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐            │
│  │   Error         │    │   Delay         │    │   Restart       │            │
│  │   Detection     │    │   Calculation   │    │   Stream        │            │
│  │                 │    │                 │    │                 │            │
│  │ onError()       │    │ 1s, 2s, 4s...   │    │ startLastPrice  │            │
│  │ onCompleted()   │    │ Max: 30s        │    │ Stream()        │            │
│  └─────────────────┘    └─────────────────┘    └─────────────────┘            │
└─────────────────────────────────────────────────────────────────────────────────┘
```

## 📊 Monitoring & Statistics

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                            Service Statistics                                   │
│                                                                                 │
│  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐            │
│  │   Trade         │    │   Price         │    │   Error         │            │
│  │   Metrics       │    │   Metrics       │    │   Metrics       │            │
│  │                 │    │                 │    │                 │            │
│  │ • Processed     │    │ • Received      │    │ • Total Errors  │            │
│  │ • Errors        │    │ • Last Price    │    │ • Error Rate    │            │
│  │ • Received      │    │ • Trade Data    │    │ • Reconnections │            │
│  └─────────────────┘    └─────────────────┘    └─────────────────┘            │
└─────────────────────────────────────────────────────────────────────────────────┘
```

## 🎯 Key Components

### **Core Services:**

- `MarketDataStreamingService` - Main processing service
- `TradeBatchRepository` - High-performance database operations
- `StreamingServiceController` - REST API for monitoring

### **Entities:**

- `TradeEntity` - Unified entity for prices and trades
- `TradeKey` - Composite key (figi, time, direction)
- `ShareEntity` - Reference data for shares
- `FutureEntity` - Reference data for futures

### **Configuration:**

- `GrpcConfig` - gRPC client configuration
- Application properties for different environments
- SQL scripts for database setup
