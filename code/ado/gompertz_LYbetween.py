from math import exp, isnan
from scipy.special import exp1
from numpy import genfromtxt, savetxt
import sys, argparse

def main():
	startage, endage, a, b, infile, outfile = check_arg(sys.argv[1:])

	if infile is None:
		if a is None or b is None:
			raise ValueError('you must specify an input file or BOTH a and b')

		LY = gompertz_lifeyears(par=[a, b], minage=startage, maxage=endage)

		if outfile is None:
			print LY
		else:
			with open(outfile, 'w') as f:
				f.write('%s' % LY)

	else:  # infile specified
		if outfile is None:
			raise ValueError('you must specify an output file with an input file')

		gompertz_parameters = genfromtxt(infile, delimiter=',')
		lifeyears = [ gompertz_lifeyears(par=p, minage=startage, maxage=endage) for p in gompertz_parameters ]

		with open(outfile, 'w') as f:
			savetxt(f, lifeyears, fmt='%9g')


def check_arg(args=None):
	parser = argparse.ArgumentParser(description='Compute expected life years between startage and endage for a person alive at startage')
	parser.add_argument('--startage',
						type=float,
						help='Starting age for expected life years calculation',
						required='True')
	parser.add_argument('--endage',
						type=float,
						help='Ending age for expected life years calculation',
						required='True')
	parser.add_argument('-a', '--intercept',
						type=float,
						help='Gompertz intercept; "a" in exp(a+bx)')
	parser.add_argument('-b', '--slope',
						type=float,
						help='Gompertz slope; "b" in exp(a+bx)')
	parser.add_argument('-i', '--input',
						type=str,
						help='CSV of Gompertz parameters; int in col 1, slope in col 2')
	parser.add_argument('-o', '--output',
						type=str,
						help='File to output expected life years to')

	results = parser.parse_args(args)
	return (results.startage,
			results.endage,
			results.intercept,
			results.slope,
			results.input,
			results.output)

def gompertz_lifeyears(par, minage, maxage):
	a=par[0]
	b=par[1]
	if -0.00001 < b < 0.00001:  # b is approximately 0
		return exp(-a) - exp(-a - exp(a) * (maxage - minage) )
	else:
		f_min = 1 / b * exp(a + b * minage)
		f_max = 1 / b * exp(a + b * maxage)
		cons_of_integ = exp(f_min)

		if b>0:
			LY = -1 * cons_of_integ / b * ( exp1(f_max) - exp1(f_min) )
		else:
			LY = -1 * cons_of_integ / b * ( exp1(complex(f_max)) - exp1(complex(f_min)) ).real

		if isnan(LY) and gompertz_survival(a, b, minage, minage+0.01)<0.00001:  # everyone dies instantly
			return 0.0
		else:
			return LY

def gompertz_survival(a, b, minage, age):
	return exp( 1 / b * ( exp(a + b*minage) - exp(a + b*age) ) )

if __name__ == '__main__':
	main()
