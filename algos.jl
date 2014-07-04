# Some code for Tim Roughgarden's algorithms part 2 course

function read_jobs(fname)
    f = open(fname)
    line = readline(f)
    numjobs = int(line)
    a = Array((Int, Int), numjobs)
    for i in 1:numjobs
        # tuple is (weight, length)
        line = readline(f)
        a[i] = tuple(map(int, split(line))...)
    end
    return a
end

# 'correct' uses the ratio between the weight and the length
# incorrect uses the difference
function order_jobs(a::Array, correct::Bool)
    if (correct) 
        ordered = sort(a, by=x->(x[1] / x[2]), rev=true)
    else
        ordered = sort(a, by=x->(x[1] - x[2]), rev=true)
    end
    return ordered
end

function compute_weighted_sum(a::Array)
    time = 0
    sum = 0
    for x in a
        time += x[2]
        sum += x[1] * time
    end
    return sum
end

function problem1(fname::String, correct::Bool)
    raw_data = read_jobs(fname)
    ordered_jobs = order_jobs(raw_data, correct)
    sum = compute_weighted_sum(ordered_jobs)
    return sum
end

assert(compute_weighted_sum([(3,1), (2,2), (1,3)]) == 15)
assert(problem1("1-1.txt", false) == 11336)
assert(problem1("1-1.txt", true) == 10548)
