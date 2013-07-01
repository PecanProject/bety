class Float
  def pretty_s
    num = "%.12g" % self
    num.sub!(/\.(.*?)0+$/,".$1")
    # might be like 2. at this point
    num = num[0..-2] if num[-1] == '.'
    num
  end



=begin

Examples for given values of num and n:

num  |  n  |  d  | power | magnitude | shifted | rounded_n
 99  |  2  |  2  |  0    |    1      |   99    |   99
100  |  2  |  2  |  0    |    1      |  100    |  100
101  |  2  |  3  |  -1   |   .1      |   10    |  100
.1   |  2  |  

... [to finish]


=end

  def round_to_significant_digit(n)
    num = self
    if num == 0 # treat 0 specially: we can't take the log of it below
      return 0.to_f;
    end

    d = (Math.log10(num.abs)).ceil;
    power = n - d.to_i;

    magnitude = (10 ** power).to_f
    shifted = (num*magnitude).round;
    #puts "shifted class is #{shifted.class}; magnitude has class #{magnitude.class} and value #{magnitude}"
    rounded_n = shifted/magnitude;
    return rounded_n.to_f
  end

end
