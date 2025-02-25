function read_files(files, num_samples; type = Complex{Int16})
    measurement = get_measurement(files, num_samples, type)
    streams = open.(files)
    measurement_channel = Channel{typeof(measurement)}()
    Base.errormonitor(Threads.@spawn begin
        try
            while true
                read_measurement!(streams, measurement)
                push!(measurement_channel, measurement)
            end
        catch e
            if e isa EOFError
                println("Reached end of file.")
            else
                rethrow(e)
            end
        finally
            close(measurement_channel)
        end
    end)
    return measurement_channel
end

function get_measurement(files, num_samples, type)
    files isa AbstractVector ? Matrix{type}(undef, num_samples, length(files)) :
    Vector{type}(undef, num_samples)
end

function read_measurement!(streams::AbstractVector, measurements)
    foreach(
        (stream, measurement) -> read!(stream, measurement),
        streams,
        eachcol(measurements),
    )
end

function read_measurement!(stream, measurement)
    read!(stream, measurement)
end