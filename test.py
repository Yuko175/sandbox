def fizzbuzz():
    """
    1から20までの数字に対してFizzBuzzルールを適用する関数。
    """
    for i in range(1, 21):
        fizz = ""
        if i % 3 == 0:
            fizz += "Fizz"
        if i % 5 == 0:
            fizz += "Buzz"
        
        if fizz:
            print(f"{i}: {fizz}")
        else:
            print(f"{i}: {i}")

if __name__ == "__main__":
    fizzbuzz()
