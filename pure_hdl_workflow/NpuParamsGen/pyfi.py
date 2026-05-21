"""
###################################################################################################
#                                                                                                 #
#                                    Python Fixed Point                                           #
#                                                                                                 #
###################################################################################################
Python Fixed-Point Library (PyFi) provides an alternative solution to MATLAB's fi command,
for free!

The difference is that the output can actually be printed in the screen rather than just creating
an fi object. This option can be quite handy while working with fixed-point implementations on
limited hardware, as it usually require a lot of look up tables. Therefore, having the values
available in hex format makes preparing the tables a breeze. There is also the option to return a
list of values with the desired type of conversion, showing the values that are not corrected input
for the configuration set by the user. This means that the input values will be checked for range
based on the class configuration set by the user.

The main.py file contains 2 examples using terminal print and return values options.
"""

import math


class fi:
    """
    Fixed Point class holding information about fixed point format used

    Attributes
    ----------
        signed : bool
            Signedess (signed or unsigned)
        word_len : int
            Number of bits used to represent the value
        frac_len : int
            Fractional bits (mantissa)
        fixed: bool, optional
            Format used for convertion
                True = Floating to fixed point
                False = Fixed to floating point
        return_val: bool, optional
            Selects type of output, return values or print
            on the console
    Methods
    -------
        _convert_to_fixed(values):
            Helper function to convert values from float to fixed
        _convert_to_float(values):
            Helper function to convert values from fixed to float
        __call__(value):
            Prints or returns the value converted to desired format
    """

    # Class constructor
    def __init__(self, signed=True, word_len=32, frac_len=31,
                 fixed=True, return_val=False):
        """
        Sets default word and fractional bits checking inputs

        Parameters
        ----------
            signed : bool, optional
                Signedess (signed or unsigned)
            word_len : int, optional
                Number of bits used to represent the value
            frac_len : int, optional
                Fractional bits (mantissa)
            fixed: bool, optional
                Format used for convertion.
                True = Floating to fixed point
                False = Fixed to floating point
            return_val: bool, optional
                Selects type of output, return values or print
                on the console
        """

        self._signed = signed
        self._word_len = word_len
        _bits = self._word_len
        if (self._signed):
            _bits -= 1
        if (frac_len <= _bits):
            self._frac_len = frac_len
        self._fixed = fixed
        self._return_val = return_val

    # Signed getter and setter
    @property
    def signed(self):
        return self._signed

    @signed.setter
    def signed(self, value):
        if (type(value) is bool):
            self._signed = value

    # Word length getter and setter
    @property
    def word_len(self):
        return self._word_len

    @word_len.setter
    def word_len(self, value):
        if (type(value) is int):
            self._word_len = value

    # Fractional length getter and setter
    @property
    def frac_len(self):
        return self._frac_len

    @frac_len.setter
    def frac_len(self, value):
        _bits = self._word_len
        if (self._signed):
            _bits -= 1
        if (value <= _bits and type(value) is int):
            self._frac_len = value

    # Format (fixed/float) getter and setter
    @property
    def fixed(self):
        return self._fixed

    @fixed.setter
    def fixed(self, value):
        if (type(value) is bool):
            self._fixed = value

    # Return value getter and setter
    @property
    def return_val(self):
        return self._return_val

    @return_val.setter
    def return_val(self, value):
        if (type(value) is bool):
            self._return_val = value

    # Converts input float values to fixed point
    def _convert_to_fixed(self, values):
        """
        Helper function to convert floating values into fixed point
        Parameters
        ----------
        value : list
            List of floats to be converted to fixed point
        Returns
        -------
        out_vals: list
            List of fixed point integers
        """

        # Local variables
        dec_text = ""
        hex_text = ""
        bin_text = ""
        out_vals = []

        # Calculating fractional digits to represent floats
        precision = math.ceil(self._frac_len / 3)
        precision_txt = "{:." + str(precision) + "f}"

        # Check if it is signed
        if (self._signed):
            for val in values:
                # Calculate numerical limit
                limit_val = 2 ** (self._word_len - self._frac_len) - (2 ** (self._word_len - self._frac_len - 1))
                # Check if it is positive value
                if (val > 0):
                    dec_text = dec_text + precision_txt.format(val) + ","
                    # Check if value is above the limit
                    if (val > limit_val):
                        if not (self._return_val):
                            print("\nWARNING: Value is too high, using", limit_val, "instead of", val,
                                  "( index:", values.index(val), ")")
                        val = limit_val
                    elif (val == limit_val):
                        check_val = round((limit_val - 1 / (2 ** self._word_len)), precision)
                        if not (self._return_val):
                            print("WARNING:", val, "can not be represented,", check_val,
                                  "will be used instead", "( index:", values.index(val), ")")
                        val = check_val
                        dec_text = ''
                        dec_text = dec_text + precision_txt.format(val) + ","
                    num = math.ceil(val * (2 ** (self._word_len - (self._word_len - self._frac_len))))
                    # Check if value is less than minimal possible
                    if (num <= 0):
                        num = 0
                    hex_text = hex_text + ("0x" + hex(num)[2:].zfill(int(self._word_len / 4))) + ","
                    bin_text = bin_text + ("0b" + bin(num)[2:].zfill(self._word_len)) + ","
                    if (self._return_val):
                        out_vals.append(num)
                # If negative
                else:
                    # Check if value is above the limit
                    if ((-1) * val > limit_val):
                        if not (self._return_val):
                            print("\nWARNING: Value is too low, using", -limit_val, "instead of", val,
                                  "( index:", values.index(val), ")")
                        val = -limit_val
                    num = (2 ** self._word_len
                           ) + (2 ** (self._word_len - self._frac_len)
                                ) + int(val * (2 ** (self._word_len -
                                                     (self._word_len - self._frac_len)
                                                     )) - (2 ** (self._word_len - self._frac_len)))
                    # Check if value is less than minimal possible
                    if (num == 2 ** self._word_len):
                        num = 0
                    hex_text = hex_text + ("0x" + hex(num)[2:].zfill(int(self._word_len / 4))) + ","
                    bin_text = bin_text + ("0b" + bin(num)[2:].zfill(self._word_len)) + ","
                    dec_text = dec_text + precision_txt.format(val) + ","
                    if (self._return_val):
                        out_vals.append(num)
        # If unsigned
        else:
            for val in values:
                # Check if it is positive value
                if (val < 0):
                    if not (self._return_val):
                        print("\nWARNING: Negative value, using 0 instead of", val,
                              "( index:", values.index(val), ")")
                    val = 0
                if (val > 2 ** (self._word_len - self._frac_len)):
                    if not (self._return_val):
                        print("\nWARNING: Value is too high, using", 2 ** (self._word_len - self._frac_len),
                              "instead of", val, "( index:", values.index(val), ")")
                    val = 2 ** (self._word_len - self._frac_len)
                num = math.ceil(val * (2 ** (self._word_len - (self._word_len - self._frac_len))) - 1)
                hex_text = hex_text + ("0x" + hex(num)[2:].zfill(int(self._word_len / 4))) + ","
                bin_text = bin_text + ("0b" + bin(num)[2:].zfill(self._word_len)) + ","
                dec_text = dec_text + precision_txt.format(val) + ","
                if (self._return_val):
                    out_vals.append(num)
        # Output values
        if not (self._return_val):
            print("\nConverted values:")
            print("-Dec (Input):", dec_text[:-1])
            print("-Hex (Output):", hex_text[:-1])
            print("-Bin (Output):", bin_text[:-1])
            return None
        # Returning values
        return out_vals

    # Converts input float values to fixed point
    def _convert_to_fixed(self, values):
        """
        Конвертирует список float в fixed-point формат (Q m.n).
        Параметры:
        - values: Список float значений для конвертации.
        Возвращает:
        - out_vals: Список целых чисел (fixed-point).
        """
        # Инициализация строк для вывода (dec, hex, bin)
        dec_text = ""
        hex_text = ""
        bin_text = ""
        out_vals = []

        # Формат для вывода float (точность по frac_len)
        precision = math.ceil(self._frac_len / 3)
        precision_txt = "{:." + str(precision) + "f}"
        # Signed режим
        if self._signed:
            for val in values:
                # Максимальное значение для Q m.n: 2^(word_len-frac_len) - 2^(word_len-frac_len-1)
                limit_val = 2 ** (self._word_len - self._frac_len) - (2 ** (self._word_len - self._frac_len - 1))
                # Положительные значения
                if val > 0:
                    dec_text += precision_txt.format(val) + ","
                    # Проверка превышения максимума
                    if val > limit_val:
                        if not self._return_val:
                            print(
                                f"\nWARNING: Value too high, using {limit_val} instead of {val} (index: {values.index(val)})")
                        val = limit_val
                    # Проверка точного попадания в максимум
                    elif val == limit_val:
                        check_val = round((limit_val - 1 / (2 ** self._word_len)), precision)
                        if not self._return_val:
                            print(
                                f"WARNING: {val} cannot be represented, using {check_val} instead (index: {values.index(val)})")
                        val = check_val
                        dec_text = dec_text[:-1] + precision_txt.format(val) + ","
                    # Конвертация: умножаем на 2^frac_len, округляем вверх
                    num = math.ceil(val * (2 ** (self._word_len - (self._word_len - self._frac_len))))
                    # Защита от нулевого или отрицательного результата
                    if num <= 0:
                        num = 0
                    hex_text += f"0x{hex(num)[2:].zfill(int(self._word_len / 4))}" + ","
                    bin_text += f"0b{bin(num)[2:].zfill(self._word_len)}" + ","
                    if self._return_val:
                        out_vals.append(num)
                # Отрицательные значения
                else:
                    # Проверка превышения минимума
                    if (-1 * val) > limit_val:
                        if not self._return_val:
                            print(
                                f"\nWARNING: Value too low, using {-limit_val} instead of {val} (index: {values.index(val)})")
                        val = -limit_val
                    # Конвертация в двухдополненное представление
                    num = (2 ** self._word_len) + (2 ** (self._word_len - self._frac_len)) + \
                          int(val * (2 ** (self._word_len - (self._word_len - self._frac_len))) - \
                              (2 ** (self._word_len - self._frac_len)))
                    # Защита от некорректного нуля
                    if num == 2 ** self._word_len:
                        num = 0
                    hex_text += f"0x{hex(num)[2:].zfill(int(self._word_len / 4))}" + ","
                    bin_text += f"0b{bin(num)[2:].zfill(self._word_len)}" + ","
                    dec_text += precision_txt.format(val) + ","
                    if self._return_val:
                        out_vals.append(num)
        # Unsigned режим
        else:
            for val in values:
                # Отрицательные значения не поддерживаются
                if val < 0:
                    if not self._return_val:
                        print(f"\nWARNING: Negative value, using 0 instead of {val} (index: {values.index(val)})")
                    val = 0
                # Проверка превышения максимума
                if val > 2 ** (self._word_len - self._frac_len):
                    if not self._return_val:
                        print(
                            f"\nWARNING: Value too high, using {2 ** (self._word_len - self._frac_len)} instead of {val} (index: {values.index(val)})")
                    val = 2 ** (self._word_len - self._frac_len)
                # Конвертация: умножаем на 2^frac_len, округляем вверх, вычитаем 1
                num = math.ceil(val * (2 ** (self._word_len - (self._word_len - self._frac_len))) - 1)
                hex_text += f"0x{hex(num)[2:].zfill(int(self._word_len / 4))}" + ","
                bin_text += f"0b{bin(num)[2:].zfill(self._word_len)}" + ","
                dec_text += precision_txt.format(val) + ","
                if self._return_val:
                    out_vals.append(num)

        # Вывод в консоль, если return_val=False
        if not self._return_val:
            print("\nConverted values:")
            print("-Dec (Input):", dec_text[:-1])
            print("-Hex (Output):", hex_text[:-1])
            print("-Bin (Output):", bin_text[:-1])
            return None

        # Возвращаем список fixed-point значений
        return out_vals

    # Class call method
    def __call__(self, value):
        """
        Prints the desired conversion based on class properties.
        Use this function for visual conversion on terminal.

        Parameters
        ----------
        value : list,float,int
            The value to be converted. It supports a list of floats,
            a list of integers, a float or a integer.

        Returns
        -------
        converted_values : list
            Returns the converted values based on the class settings.
            If return_val is False, there is nothing returned.
        """

        # Printing header if return_val is False
        if not (self._return_val):
            print("\nPYTHON FIXED POINT CONVERTER\n")
            print("Configuration:")
            if (self._fixed):
                print("-Type of conversion:", "Floating to fixed point")
            else:
                print("-Type of conversion:", "Fixed to floating point")
            if (self._signed):
                print("-Signedness:", "Signed")
            else:
                print("-Signedness:", "Unsigned")
            print("-Total bits:", self._word_len)
            print("-Fractional bits:", self._frac_len)

        # Converting input type to list
        input_type_list = isinstance(value, (list, tuple))
        values = [value] if not input_type_list else value

        # Float to fixed point conversion
        converted_values = self._convert_to_fixed(values) if self._fixed else self._convert_to_float(values)
        if converted_values is None:
            print("Ошибка: _convert_to_fixed вернул None для значений:", values)
            raise ValueError("PyFi не смог конвертировать значения")

        # Returning the converted values with same type as input
        if self._return_val:
            if input_type_list:
                return [f"0x{hex(val)[2:].zfill(int(self._word_len / 4))}" for val in converted_values]
            else:
                return f"0x{hex(converted_values[0])[2:].zfill(int(self._word_len / 4))}"