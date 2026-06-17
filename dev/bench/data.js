window.BENCHMARK_DATA = {
  "lastUpdate": 1781724576969,
  "repoUrl": "https://github.com/qomer0507/jsip-exchange",
  "entries": {
    "Order book benchmark": [
      {
        "commit": {
          "author": {
            "email": "curvedmagician5@gmail.com",
            "name": "qomer0507",
            "username": "qomer0507"
          },
          "committer": {
            "email": "noreply@github.com",
            "name": "GitHub",
            "username": "web-flow"
          },
          "distinct": true,
          "id": "a1c20f6d34cf97bb8a3b6493528dabc67e87bf3e",
          "message": "Merge branch 'jane-street-immersion-program:main' into main",
          "timestamp": "2026-06-17T15:24:39-04:00",
          "tree_id": "b105f708f1d0a3bfac0fc8f703926fc5cb5958f3",
          "url": "https://github.com/qomer0507/jsip-exchange/commit/a1c20f6d34cf97bb8a3b6493528dabc67e87bf3e"
        },
        "date": 1781724576710,
        "tool": "customSmallerIsBetter",
        "benches": [
          {
            "name": "find_match (n=10)",
            "value": 25.86431788332586,
            "unit": "ns"
          },
          {
            "name": "find_match (n=50)",
            "value": 25.63052803938191,
            "unit": "ns"
          },
          {
            "name": "find_match (n=100)",
            "value": 25.747412415495635,
            "unit": "ns"
          },
          {
            "name": "find_match (n=500)",
            "value": 25.25502604689885,
            "unit": "ns"
          },
          {
            "name": "find_match_miss (n=10)",
            "value": 130.16916263971885,
            "unit": "ns"
          },
          {
            "name": "find_match_miss (n=50)",
            "value": 580.202459002764,
            "unit": "ns"
          },
          {
            "name": "find_match_miss (n=100)",
            "value": 1148.953452031252,
            "unit": "ns"
          },
          {
            "name": "find_match_miss (n=500)",
            "value": 5507.891376670923,
            "unit": "ns"
          },
          {
            "name": "best_bid_offer (n=10)",
            "value": 249.33649338127958,
            "unit": "ns"
          },
          {
            "name": "best_bid_offer (n=50)",
            "value": 1178.1960371440205,
            "unit": "ns"
          },
          {
            "name": "best_bid_offer (n=100)",
            "value": 2204.6945962441505,
            "unit": "ns"
          },
          {
            "name": "best_bid_offer (n=500)",
            "value": 10938.0263634193,
            "unit": "ns"
          },
          {
            "name": "add+remove (n=100)",
            "value": 1751.06773809192,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_cross (n=10)",
            "value": 1267.349199153426,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_cross (n=50)",
            "value": 5671.078984180902,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_cross (n=100)",
            "value": 11304.444650944044,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_cross (n=500)",
            "value": 54438.15786173448,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_miss (n=10)",
            "value": 693.1407373722119,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_miss (n=50)",
            "value": 3016.2472147975955,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_miss (n=100)",
            "value": 5945.716660885997,
            "unit": "ns"
          },
          {
            "name": "submit_ioc_miss (n=500)",
            "value": 29012.9170592807,
            "unit": "ns"
          },
          {
            "name": "submit_sweep_10_levels",
            "value": 5653.450833906463,
            "unit": "ns"
          },
          {
            "name": "submit_sweep_50_levels",
            "value": 88850.75594980974,
            "unit": "ns"
          },
          {
            "name": "submit_sweep_100_levels",
            "value": 333433.3729249259,
            "unit": "ns"
          },
          {
            "name": "find_match_alloc (n=100)",
            "value": 25.703148240763095,
            "unit": "ns"
          }
        ]
      }
    ]
  }
}