class Float
  def pretty_s
    num = "%.12g" % self
    num.sub!(/\.(.*?)0+$/,".$1")
    # might be like 2. at this point
    num = num[0..-2] if num[-1] == '.'
    num
  end


  def round_to_significant_digit(n)
    num = self
    if(num == 0)
      return 0;
    end

    d = (Math.log10(num < 0 ? -num : num)).ceil;
    power = n - d.to_i;

    magnitude = (10 ** power).to_f
    shifted = (num*magnitude).round;
    #puts "shifted class is #{shifted.class}; magnitude has class #{magnitude.class} and value #{magnitude}"
    return shifted/magnitude;
  end

end
