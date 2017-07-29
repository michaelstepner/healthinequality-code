using ArgParse
using GLM, DataFrames, Distributions

function parse_commandline()
    s = ArgParseSettings()

    @add_arg_table s begin
        "--input"
            help = "input CSV with counts of deaths and survivals by Age x Group"
            arg_type = String
            required = true
        "--output"
            help = "output CSV with Gompertz parameter estimates"
            arg_type = String
            required = true
        "--vce"
            help = "type of VCV matrix computed; either 'oim' or 'builtin'"
            arg_type = String
            default = "oim"
    end

    return parse_args(s)
end

function gompertzreg(df, vce)
  # Perform a Gompertz MLE regression, return the coefficients and Cholesky-decomposed covariance matrix as a DataFrame.

  model = try
      GLM.glm(@formula(mort ~ age), df, Binomial(), LogLink(), wts=1.0*df[:count].data, start=(-10,0.1))
    catch err
      err
    end

  if isa(model, DataFrames.DataFrameRegressionModel)
    coef = GLM.coef(model)'

    if vce=="oim"
      vcov = vcov_Gompertz_OIM(model, df)
    elseif vce=="builtin"
      vcov = GLM.vcov(model)
    else
      throw(ArgumentError("vce must be oim or builtin"))
    end

    A = chol([vcov[2,2] vcov[2,1]; vcov[1,2] vcov[1,1]])
    return DataFrame(gomp_int = coef[1], gomp_slope = coef[2], A_slope_1 = A[1,1], A_int_1 = A[1,2], A_int_2 = A[2,2])

  elseif isa(model, ErrorException)
    println("caught error in _grp $(dec(df[1,:_grp])): $(model.msg) (Likely 0 deaths.)")
    return DataFrame(gomp_int = 0, gomp_slope = 0, A_slope_1 = 0, A_int_1 = 0, A_int_2 = 0)

  elseif isa(model, LinAlg.PosDefException)
    println("caught error in _grp $(dec(df[1,:_grp])): LinAlg.PosDefException (Likely insufficient observations)")
    return DataFrame(gomp_int = 0, gomp_slope = 0, A_slope_1 = 0, A_int_1 = 0, A_int_2 = 0)

  else
    throw(model)

  end

end

function vcov_Gompertz_OIM(model, df)
  # Computes the OIM variance-covariance matrix for a Gompertz GLM model

  df_alive = df[df[:mort] .== 0, :]
  df_alive[:predmort] = exp( GLM.coef(model)[1] + GLM.coef(model)[2] * df_alive[:age] )

  OIM_contribution = DataFrame()
  OIM_contribution[:a2] = df_alive[:count] .* df_alive[:predmort] ./ (1-df_alive[:predmort]).^2
  OIM_contribution[:ab] = OIM_contribution[:a2] .* df_alive[:age]
  OIM_contribution[:b2] = OIM_contribution[:ab] .* df_alive[:age]

  OIM_elements = aggregate(OIM_contribution, sum)
  return Symmetric(inv([OIM_elements[1,:a2_sum] OIM_elements[1,:ab_sum]; OIM_elements[1,:ab_sum] OIM_elements[1,:b2_sum]]))

end

function main()

    # Parse arguments
    parsed_args = parse_commandline()

    # Load data
    data = readtable(parsed_args["input"])

    # Run Gompertz MLE regression on each by-group
    gompBY = by(data, :_grp, df -> gompertzreg(df, parsed_args["vce"]) )

    # Output results
    writetable(parsed_args["output"], gompBY)

end

main()
