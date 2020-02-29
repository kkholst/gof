/*!
  @file test_misc.cpp
  @author Klaus K. Holst
  @copyright 2018, Klaus Kähler Holst

  @brief Unit tests

*/

#include <catch2/catch.hpp>
#include <spdlog/spdlog.h>
#include "utils.hpp"
#include "cumres.hpp"

using namespace arma;

bool True() { return(true); }

TEST_CASE("Sanity check", "[sanity]") {
  spdlog::info("Sanity checks!");
  REQUIRE(True());
  REQUIRE(2 == 2);
  CHECK(1 == 1); // Continue even if test fails
  REQUIRE(100.5 == Approx(100).epsilon(0.01)); // Allow 1% difference
  REQUIRE(100 == Approx(100));
}

TEST_CASE("Armadillo check", "[arma]") {
  vec x = {1,2,3};
  spdlog::info("Size: {:d}", x.n_elem);
  std::cout << trans(x) << std::endl;
  REQUIRE(x.n_elem == 3);
}

TEST_CASE("Cluster-id", "[utils]") {

  SECTION("Test all up to 10") {
    REQUIRE(1==1);
  }
  
  SECTION("Test all up to 11") {
    REQUIRE(1==1);
  }

}



