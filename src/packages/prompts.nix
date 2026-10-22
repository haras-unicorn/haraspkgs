{
  self.overlays.overlays.prompts = {
    flake = true;
    value = final: prev: {
      war-and-peace = final.fetchurl {
        name = "pg2600.txt";
        url = "https://www.gutenberg.org/cache/epub/2600/pg2600.txt";
        hash = "sha256-LVuyrV9CJ2XnFGF+Ifoxu6+JWKp5aCyG/KZmD8xdGys=";
      };

      les-miserables = final.fetchurl {
        name = "pg135.txt";
        url = "https://www.gutenberg.org/cache/epub/135/pg135.txt";
        hash = "sha256-bPO51vxeb3M3N0JSZ9OvKW1/mfm5/R0lWjq3aJpjRqs=";
      };

      count-of-monte-cristo = final.fetchurl {
        name = "pg1184.txt";
        url = "https://www.gutenberg.org/cache/epub/1184/pg1184.txt";
        hash = "sha256-ZPjVz6UfzsuQSr9zEtOV1RKnGBfnNZuRKIvrUFF8ODY=";
      };

      don-quixote = final.fetchurl {
        name = "pg996.txt";
        url = "https://www.gutenberg.org/cache/epub/996/pg996.txt";
        hash = "sha256-KGQUPprd9JjBxf1YXbSh/z4GZRw0TN3wkxNC8aDOJNQ=";
      };

      ulysses = final.fetchurl {
        name = "pg4300.txt";
        url = "https://www.gutenberg.org/cache/epub/4300/pg4300.txt";
        hash = "sha256-4DCUYm+VKM8/woeknW7b2/R81ASDyxPOswHnThXrv54=";
      };

      moby-dick = final.fetchurl {
        name = "pg2701.txt";
        url = "https://www.gutenberg.org/cache/epub/2701/pg2701.txt";
        hash = "sha256-kHQg22xLaMcOKYjNKtnIz3kThmegG2M3bRjdF/7xoYs=";
      };
    };
  };
}
