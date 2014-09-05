const test_dir = "jl_input"

function generate_rand_strings(n::Int)
    for i in 1:n
        len = rand(1:10000000)
        f = open("$(test_dir)/$(i)","w")
        write(f, randstring(len))
        close(f)
    end
end

generate_rand_strings(3)