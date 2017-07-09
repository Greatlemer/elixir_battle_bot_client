defmodule NoughtsAndCrosses.Strategy do
  import NoughtsAndCrosses.StrategyPlan

  strategy "as X", "when the board represents:",
    """
     |O| 
    -+-+-
     | | 
    -+-+-
     | | 
    """,

    play:
    """
    X| | 
    -+-+-
     | | 
    -+-+-
     | | 
    """

  strategy "as X", "when the board represents:",
    """
     |O| 
    -+-+-
     |X| 
    -+-+-
     | | 
    """,

    play:
    """
     | | 
    -+-+-
     | | 
    -+-+-
    X| | 
    """

  strategy "as X", "when the board represents:",
    """
    X|O| 
    -+-+-
     | | 
    -+-+-
     | | 
    """,

    play:
    """
     | | 
    -+-+-
     | | 
    -+-+-
    X| | 
    """

  strategy "as X", "when the board represents:",
    """
    X| |O
    -+-+-
     | | 
    -+-+-
     | | 
    """,

    play:
    """
     | | 
    -+-+-
     | | 
    -+-+-
     | |X
    """

  strategy "as X", "when the board represents:",
    """
     |X| 
    -+-+-
     | | 
    -+-+-
     | |O
    """,

    play:
    """
     | | 
    -+-+-
     | | 
    -+-+-
    X| | 
    """


  strategy "as X", "when the board represents:",
    """
     |X| 
    -+-+-
     | | 
    -+-+-
    X|O|O
    """,

    play:
    """
    X| | 
    -+-+-
     | | 
    -+-+-
     | | 
    """

end