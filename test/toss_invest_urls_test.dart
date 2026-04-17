import 'package:dopamine_assets/core/broker/toss_invest_urls.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('tossInvestStockOrderUri', () {
    test('US ticker uses path as-is (uppercase)', () {
      expect(
        tossInvestStockOrderUri(assetClass: 'us_stock', symbol: 'tsla'),
        Uri.parse('https://tossinvest.com/stocks/TSLA/order'),
      );
    });

    test('US Yahoo-style dot ticker maps to hyphen', () {
      expect(
        tossInvestStockOrderUri(assetClass: 'us_stock', symbol: 'BRK.B'),
        Uri.parse('https://tossinvest.com/stocks/BRK-B/order'),
      );
    });

    test('KR Yahoo suffix maps to A + six digits', () {
      expect(
        tossInvestStockOrderUri(
          assetClass: 'kr_stock',
          symbol: '005930.KS',
        ),
        Uri.parse('https://tossinvest.com/stocks/A005930/order'),
      );
    });

    test('KR bare digits pad to six', () {
      expect(
        tossInvestStockOrderUri(assetClass: 'kr_stock', symbol: '1234'),
        Uri.parse('https://tossinvest.com/stocks/A001234/order'),
      );
    });

    test('KR already Toss-style segment', () {
      expect(
        tossInvestStockOrderUri(assetClass: 'kr_stock', symbol: 'a005930'),
        Uri.parse('https://tossinvest.com/stocks/A005930/order'),
      );
    });

    test('crypto and other classes return null', () {
      expect(
        tossInvestStockOrderUri(assetClass: 'crypto', symbol: 'BTC'),
        isNull,
      );
      expect(
        tossInvestStockOrderUri(assetClass: 'jp_stock', symbol: '7203.T'),
        isNull,
      );
    });

    test('unparseable KR symbol returns null', () {
      expect(
        tossInvestStockOrderUri(assetClass: 'kr_stock', symbol: 'SAMSUNG'),
        isNull,
      );
    });
  });

  group('exchangeViewUri', () {
    test('ko + crypto opens CoinMarketCap', () {
      expect(
        exchangeViewUri(
          localeLanguageCode: 'ko',
          assetClass: 'crypto',
          symbol: 'BTC-USD',
          cryptoSlug: 'bitcoin',
        ),
        Uri.parse('https://coinmarketcap.com/currencies/bitcoin/'),
      );
      expect(
        exchangeViewUri(
          localeLanguageCode: 'ko',
          assetClass: 'crypto',
          symbol: 'RAVE',
        ),
        isNull,
      );
      expect(
        exchangeViewUri(
          localeLanguageCode: 'ko',
          assetClass: 'crypto',
          symbol: 'SIREN',
          cryptoSlug: 'siren-2',
        ),
        Uri.parse('https://coinmarketcap.com/currencies/siren/'),
      );
      expect(
        exchangeViewUri(
          localeLanguageCode: 'ko',
          assetClass: 'crypto',
          symbol: 'BTC',
          cryptoSlug: 'bitcoin',
        ),
        Uri.parse('https://coinmarketcap.com/currencies/bitcoin/'),
      );
    });

    test('non-ko crypto also routes to CoinMarketCap', () {
      expect(
        exchangeViewUri(
          localeLanguageCode: 'en',
          assetClass: 'crypto',
          symbol: 'BTC-USD',
          cryptoSlug: 'bitcoin',
        ),
        Uri.parse('https://coinmarketcap.com/currencies/bitcoin/'),
      );
    });

    test('ko locale keeps Toss routes for us/kr stocks', () {
      expect(
        exchangeViewUri(
          localeLanguageCode: 'ko',
          assetClass: 'us_stock',
          symbol: 'AAPL',
        ),
        Uri.parse('https://tossinvest.com/stocks/AAPL/order'),
      );
      expect(
        exchangeViewUri(
          localeLanguageCode: 'ko',
          assetClass: 'kr_stock',
          symbol: '005930.KS',
        ),
        Uri.parse('https://tossinvest.com/stocks/A005930/order'),
      );
    });

    test('non-ko locales route us/kr stocks to Yahoo Finance', () {
      expect(
        exchangeViewUri(
          localeLanguageCode: 'en',
          assetClass: 'us_stock',
          symbol: 'AAPL',
        ),
        Uri.parse('https://finance.yahoo.com/quote/AAPL'),
      );
      expect(
        exchangeViewUri(
          localeLanguageCode: 'ja',
          assetClass: 'kr_stock',
          symbol: '005930.KS',
        ),
        Uri.parse('https://finance.yahoo.com/quote/005930.KS'),
      );
    });

    test('jp_stock routes to Yahoo Japan', () {
      expect(
        exchangeViewUri(
          localeLanguageCode: 'ja',
          assetClass: 'jp_stock',
          symbol: '7203.T',
        ),
        Uri.parse('https://finance.yahoo.co.jp/quote/7203.T'),
      );
      expect(
        exchangeViewUri(
          localeLanguageCode: 'ja',
          assetClass: 'jp_stock',
          symbol: '9984',
        ),
        Uri.parse('https://finance.yahoo.co.jp/quote/9984.T'),
      );
    });

    test('cn_stock routes to Eastmoney', () {
      expect(
        exchangeViewUri(
          localeLanguageCode: 'zh',
          assetClass: 'cn_stock',
          symbol: '600519.SS',
        ),
        Uri.parse('https://quote.eastmoney.com/sh600519.html'),
      );
      expect(
        exchangeViewUri(
          localeLanguageCode: 'zh',
          assetClass: 'cn_stock',
          symbol: '000001.SZ',
        ),
        Uri.parse('https://quote.eastmoney.com/sz000001.html'),
      );
    });

    test('commodity routes to Yahoo Finance', () {
      expect(
        exchangeViewUri(
          localeLanguageCode: 'ko',
          assetClass: 'commodity',
          symbol: 'GC=F',
        ),
        Uri.parse('https://finance.yahoo.com/quote/GC=F'),
      );
      expect(
        exchangeViewUri(
          localeLanguageCode: 'en',
          assetClass: 'commodity',
          symbol: 'CL=F',
        ),
        Uri.parse('https://finance.yahoo.com/quote/CL=F'),
      );
    });
  });
}
