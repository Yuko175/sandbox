def fizzbuzz():
    """
    1から20までの数字に対してFizzBuzzルールを適用する関数。
    """
    for i in range(1, 21):
        if i % 3 == 0 and i % 5 == 0:
            print(f"{i}: FizzBuzz")
        elif i % 3 == 0:
            print(f"{i}: Fizz")
        elif i % 5 == 0:
            print(f"{i}: Buzz")
        else:
            print(f"{i}: {i}")

if __name__ == "__main__":
    fizzbuzz()
