#!/bin/bash
#
# optimize_website_images.sh
#
# Script's documentation page: http://www.adminbuntu.com/website_image_optimization
#
# Customize and rename this script for your website. Then, after images have been changed and
# before changes are pushed to the server, run this script to optimize all images in the site for
# the web.
#
# See the documentation page for instructions on installing optipng and jpegtran.
#
# Copyright 2013 Andrew Ault
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy of this software
# and associated documentation files (the "Software"), to deal in the Software without restriction,
# including without limitation the rights to use, copy, modify, merge, publish, distribute,
# sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in all copies or
# substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT
# NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
# DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#
# customize this block for your website
SITE_DIRECTORY = "/path/here"
#
#
cd $SITE_DIRECTORY
#
# optimize site's PNG images
find . -name '*.png' -exec optipng {} \;
#
# optimize site's JPEG images
find . -regex ".*\.\(jpeg\|jpg\)" -print0 | xargs -0 -I filename jpegtran -copy none -optimize -outfile filename filename
